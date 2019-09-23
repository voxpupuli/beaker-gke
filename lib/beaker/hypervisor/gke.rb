require 'kubeclient'
require 'jsonpath'
require 'beaker-gke'
require 'googleauth'

module Beaker
  class Gke < Beaker::Hypervisor
    SERVICE_NAMESPACE = 'gke-puppetagent-ci'.freeze
    PROXY_IP = '10.236.0.3'.freeze
    PROXY_PORT = 8899
    # OS environment variable must be set to continue
    # ENV['CLIENT_CONFIG'] = 'path/.kube/config'
    # ENV['GOOGLE_APPLICATION_CREDENTIALS'] = 'path/.kube/puppetagent-ci.json'


    def initialize(hosts, options)
      begin
        ENV.fetch('CLIENT_CONFIG')
        ENV.fetch('GOOGLE_APPLICATION_CREDENTIALS')
      rescue
        raise ArgumentError, 'OS environment variable CLIENT_CONFIG and GOOGLE_APPLICATION_CREDENTIALS must be set'
      end
        @hosts = hosts
        @options = options
        @client = client
    end

    def provision
        puts caller
        @hosts.each do |host|
          hostname = generate_host_name
          create_pod(hostname)
          create_srv(hostname)
          pod = get_pod(hostname)
          host[:hostname] = pod.metadata.name
          host[:ip] = pod.status.podIP
        end
        nil
    end

    def cleanup
      @hosts.each do |host|
        delete_pod(host[:hostname])
        delete_service(host[:hostname])
      end
    end

    def connection_preference(host)
      [:ip, :hostname, :vmhostname]
    end
    
    def create_pod(name)
      pod_config=read_symbols('pod.yaml',{pod_name:name} )
      @client.create_pod(pod_config)
    end

    def get_pod(name)
      @client.get_pod(name, SERVICE_NAMESPACE)
    end

    def create_srv(name)
      service_config=read_symbols('service.yaml',{pod_name:name} )
      @client.create_service(service_config)
    end

    def delete_pod(pod_name)
      @client.delete_pod(pod_name, SERVICE_NAMESPACE, delete_options: { 'force': 1, 'grace-period': 0  } )
    end

    def delete_service(srv_name)
      begin
       if srv_name.instance_of?(String)
         client.delete_service(srv_name, SERVICE_NAMESPACE)
       else
         raise ArgumentError, 'Wrong argument type - #{srv_name.class}'
       end
     end
    rescue Kubeclient::ResourceNotFoundError => e
     puts "Service #{srv_name} could not be deleted #{e.to_s}"
    end

    private

    def client
      config = Kubeclient::Config.read(ENV['CLIENT_CONFIG'])
      context = config.context
      proxy_uri = URI::HTTP.build(host: PROXY_IP, port: PROXY_PORT)
      Kubeclient::Client.new(
          context.api_endpoint, 'v1',
          http_proxy_uri: proxy_uri,
          ssl_options: context.ssl_options,
          auth_options: context.auth_options
      )
    end

    def read_file(file_name)
      path = File.join(ROOT_DIR, 'config', file_name)
      File.read(path)
    end

    def read_symbols(file, substitution = {})
      data = read_file(file)
      Psych.load(data %substitution , symbolize_names: true)
    end
  end
end