import Kuber, MbedTLS, Base, Swagger, YAML, Base64

"""
    discover_client()

Creates a kubercontext based on whether it detects running in a pod or locally
"""
function discover_client()::Kuber.KuberContext
    host = get(envs, "KUBERNETES_SERVICE_HOST", "")
    if host == ""
        println("detected running locally, attempting kubeconfig connection")
        return kubeconfig_client("")
    end

    println("detected running in pod, attempting in-cluster connection")
    return incluster_client()
end

"""
    kubeconfig_client(kubeconfigpath::string)

Creates a kubercontext configured from a kubeconfig file. If kubeconfig path is
an empty string it will look for the KUBCONFIG envvar or default to ~/.kube/config
"""
function kubeconfig_client(kubeconfigpath::String)::Kuber.KuberContext
    envs = Base.EnvDict()

    if kubeconfigpath == ""
        default = Base.Filesystem.joinpath(Base.Filesystem.homedir(), ".kube/config")
        kubeconfigpath = get(envs, "KUBECONFIG", default)
    end
    kubecfg = YAML.load(open(kubeconfigpath))

    currentcontext = get(kubecfg, "current-context", "")
    if currentcontext == ""
        error("current kubeconfig context is empty")
    end

    println("using current context: ", currentcontext)

    clustername = ""
    username = ""
    for context in kubecfg["contexts"]
        println(context)
        if context["name"] == currentcontext
            clustername = context["context"]["cluster"]
            username = context["context"]["user"]
        end
    end

    if clustername == "" || username == ""
        error(string("could not find user or cluster for current context: ", currentcontext))
    end

    cadata = ""
    server = ""
    for cluster in kubecfg["clusters"]
        if cluster["name"] == clustername
            cadata = cluster["cluster"]["certificate-authority-data"]
            server = cluster["cluster"]["server"]
        end
    end

    if server == ""
        error(string("could not find cluster for current context: ", currentcontext))
    end

    println("using server: ", server)

    clientcert = ""
    clientkey = ""
    for user in kubecfg["users"]
        if user["name"] == username
            clientcert = user["user"]["client-certificate-data"]
            clientkey = user["user"]["client-key-data"]
        end
    end
    if clientcert == "" || clientkey == ""
        error("could not find client cert or key from current context: ", currentcontext)
    end

    println("using user: ", username)

    # save ssl info as temp files
    # TODO: would prefer to find a way of doing this without temp files
    capath, io = Base.Filesystem.mktemp()
    write(io, Base64.base64decode(cadata))
    close(io)

    certpath, io = Base.Filesystem.mktemp()
    write(io, Base64.base64decode(clientcert))
    close(io)

    keypath, io = Base.Filesystem.mktemp()
    write(io, Base64.base64decode(clientkey))
    close(io)
    conf = MbedTLS.SSLConfig(certpath, keypath)

    MbedTLS.ca_chain!(conf, MbedTLS.crt_parse_file(capath))
    kctx = Kuber.KuberContext()
    println("server: ", server)
    Kuber.set_server(kctx, server, tlsconfig=conf, require_ssl_verification=false)
    return kctx
end

"""
    incluster_client()

Creates a kubercontext configured from a pods enviornment.
"""
function incluster_client()::Kuber.KuberContext
    tokenFile  = "/var/run/secrets/kubernetes.io/serviceaccount/token"
    rootCAFile = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

    envs = Base.EnvDict()

    host = get(envs, "KUBERNETES_SERVICE_HOST", "")
    port = get(envs, "KUBERNETES_SERVICE_PORT", "")

    if host == "" || port == ""
        error("could not find host and/or port from environment,
         must not be running in a pod")
    end

    token = read(tokenFile, String)
    conf = MbedTLS.SSLConfig()
    MbedTLS.ca_chain!(conf, MbedTLS.crt_parse_file(rootCAFile))

    uri = string("https://", host, ":", port)
    println("using server: ", uri)

    # TODO: this needs fixed upstream to handle token refreshes
    headers = Dict("Authorization" => string("bearer ", token))

    kctx = Kuber.KuberContext()
    Kuber.set_server(kctx, uri=uri, headers=headers, tlsconfig=conf, require_ssl_verification=false)
    return kctx
end
