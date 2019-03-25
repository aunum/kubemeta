import Kuber, MbedTLS, Base, Swagger, YAML, Base64

"""
    K8sClient(uri::String, sslconfig::MbedTLS.SSLConfig, headers::Dict{String, String})

Holds the configurations for making HTTP k8s connections.
"""
mutable struct K8sClient
    server::String
    sslconfig::MbedTLS.SSLConfig
    headers::Dict{String, String}
    function K8sClient(server::String, sslconfig::MbedTLS.SSLConfig; headers::Dict{String, String}=Dict{String, String}())
        new(server, sslconfig, headers)
    end
end

function request(client::K8sClient, method::String, path::String)::HTTP.Messages.Response
    @show client
    uri = HTTP.URI(client.server)
    uri = merge(uri; path=path)
    @show uri
    println("uri: ", string(uri))
    return HTTP.request(method, string(uri), headers=client.headers, sslconfig=client.sslconfig, status_exception=false)
end

"""
    client()

Creates a K8sClient based on whether it detects running in a pod or locally.
"""
function client()::K8sClient
    envs = Base.EnvDict()
    host = get(envs, "KUBERNETES_SERVICE_HOST", "")
    if host == ""
        println("detected running locally, attempting kubeconfig connection")
        return client("")
    end

    println("detected running in pod, attempting in-cluster connection")
    return incluster_client()
end

"""
    client(kubeconfigpath::string)

Creates a K8sClient configured from a kubeconfig file. If kubeconfig path is
an empty string it will look for the KUBCONFIG envvar or default to ~/.kube/config
"""
function client(kubeconfigpath::String)::K8sClient
    envs = Base.EnvDict()

    if kubeconfigpath == ""
        default = Base.Filesystem.joinpath(Base.Filesystem.homedir(), ".kube/config")
        kubeconfigpath = get(envs, "KUBECONFIG", default)
    end
    println("kubeconfig filepath: ", kubeconfigpath)
    kubecfg = YAML.load(open(kubeconfigpath))

    currentcontext = get(kubecfg, "current-context", "")
    if currentcontext == ""
        error("current kubeconfig context is empty")
    end

    println("using current context: ", currentcontext)

    clustername = ""
    username = ""
    for context in kubecfg["contexts"]
        if context["name"] == currentcontext
            clustername = context["context"]["cluster"]
            username = context["context"]["user"]
        end
    end

    if clustername == "" || username == ""
        error(string("could not find user or cluster for current context: ", currentcontext))
    end

    # TODO: handle other auth scenarios
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
    println("capath: ", capath)

    certpath, io = Base.Filesystem.mktemp()
    write(io, Base64.base64decode(clientcert))
    close(io)
    println("certpath: ", certpath)

    keypath, io = Base.Filesystem.mktemp()
    write(io, Base64.base64decode(clientkey))
    close(io)
    println("keypath: ", keypath)

    conf = MbedTLS.SSLConfig(certpath, keypath)
    MbedTLS.config_defaults!(conf)

    cacert = MbedTLS.crt_parse_file(capath)
    println("capath: ", cacert)
    MbedTLS.ca_chain!(conf, cacert)

    return K8sClient(server, conf)
end

"""
    incluster_client()

Creates a K8sClient configured from a pods enviornment.
"""
function incluster_client()::K8sClient
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

    return K8sClient(uri, conf; headers=headers)
end

"""
    kubercontext(client::K8sClient)::Kuber.KuberContext

Creates a kubercontext from a client
"""
function kubercontext(client::K8sClient)::Kuber.KuberContext
    kctx = Kuber.KuberContext()
    Kuber.set_server(kctx, client.uri, true, headers=client.headers, sslconfig=client.sslconfig, require_ssl_verification=true)
    return kctx
end
