# frozen_string_literal: true

require 'kubeclient'
require 'beaker-gke'
require 'googleauth'

module Beaker
  class Gke < Beaker::Hypervisor
    SERVICE_NAMESPACE = 'gke-puppetagent-ci'
    PROXY_IP = '10.236.0.3'
    PROXY_PORT = 8899
    MAX_RETRIES = 5
    # OS environment variable must be set to continue
    # ENV['KUBECONFIG'] = 'path/.kube/config'
    # ENV['GOOGLE_APPLICATION_CREDENTIALS'] = 'path/.kube/puppetagent-ci.json'

    def initialize(hosts, options)
      begin
        ENV.fetch('KUBECONFIG')
        ENV.fetch('GOOGLE_APPLICATION_CREDENTIALS')
      rescue KeyError
        raise(
          ArgumentError,
          'OS environment variable KUBECONFIG and GOOGLE_APPLICATION_CREDENTIALS must be set'
        )
      end
      @hosts = hosts
      @options = options
      @client = client
      @logger = options[:logger]
    end

    def provision
      @hosts.each do |host|
        hostname = generate_host_name
        create_pod(hostname)
        create_srv(hostname)
        retries = 0

        begin
          pod = get_pod(hostname)
          raise StandardError unless pod.status.podIP
        rescue StandardError => e
          raise "Timeout: #{e.message}" unless retries <= MAX_RETRIES

          @logger.info('Retrying , could not get podIP')

          retries += 1
          sleep(2**retries)
          retry
        end

        host[:vmhostname] = "#{hostname}.gke-puppetagent-ci.puppet.net"
        host[:hostname] = hostname
        host[:ip] = pod.status.podIP
      end
      nil
    end

    def cleanup
      @hosts.each do |host|
        @logger.info("Deleting POD with ID: #{host[:hostname]}")

        delete_pod(host[:hostname])
        delete_service(host[:hostname])
      end
    end

    def connection_preference(_host)
      %i[ip vmhostname hostname]
    end

    def create_pod(name)
      pod_config = read_symbols('pod.yaml', pod_name: name)
      @client.create_pod(pod_config)
    end

    def get_pod(name)
      @client.get_pod(name, SERVICE_NAMESPACE)
    end

    def create_srv(name)
      service_config = read_symbols('service.yaml', pod_name: name)
      @client.create_service(service_config)
    end

    def delete_pod(pod_name)
      @client.delete_pod(
        pod_name,
        SERVICE_NAMESPACE,
        delete_options: { 'force': 1, '--grace-period': 0 }
      )
    end

    def delete_service(srv_name)
      client.delete_service(srv_name, SERVICE_NAMESPACE)
    rescue Kubeclient::ResourceNotFoundError => e
      @logger.info("Service #{srv_name} could not be deleted #{e}")
    end

    private

    def client
      config = Kubeclient::Config.read(ENV['KUBECONFIG'])
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
      File.read(File.join(ROOT_DIR, 'config', file_name))
    end

    def read_symbols(file, substitution = {})
      data = read_file(file)
      Psych.load(data % substitution, symbolize_names: true)
    end
  end
end
