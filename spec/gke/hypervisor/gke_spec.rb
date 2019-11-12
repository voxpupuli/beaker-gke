# frozen_string_literal: true

describe Beaker::Gke do
  let(:hosts) { make_hosts }

  let(:options) { { logger: logger } }

  let(:logger) do
    logger = instance_double('logger')
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
    allow(logger).to receive(:warn)
    allow(logger).to receive(:error)
    allow(logger).to receive(:notify)
    logger
  end

  let(:config) { instance_double('config') }

  let(:context) do
    instance_double('context',
                    api_endpoint: 'v1',
                    ssl_options: {
                      verify_ssl: 1,
                      cert_store: true
                    },
                    auth_options: {
                      bearer_token: 'TOKEN_STRING'
                    })
  end

  let(:gke) { ::Beaker::Gke.new(hosts, options) }

  def pass_through_initialization
    allow(ENV).to receive(:fetch).with('KUBECONFIG').and_return('default_value')
    allow(ENV).to receive(:fetch).with('GOOGLE_APPLICATION_CREDENTIALS').and_return('default_value')
    allow(config).to receive(:context).and_return(context)
    allow(Kubeclient::Config).to receive(:read).with(ENV['KUBECONFIG']).and_return(config)
  end

  before do
    FakeFS.deactivate!
  end

  describe ' #initialize' do
    let(:env_error_message) { 'OS environment variable KUBECONFIG and GOOGLE_APPLICATION_CREDENTIALS must be set' }

    it 'raises error when KUBECONFIG and GOOGLE_APPLICATION_CREDENTIALS ENV variables are not set' do
      expect { gke }.to raise_error(ArgumentError, env_error_message)
    end

    it 'raises error when only GOOGLE_APPLICATION_CREDENTIALS ENV variable is set' do
      with_modified_env GOOGLE_APPLICATION_CREDENTIALS: 'default_value' do
        expect { gke }.to raise_error(ArgumentError, env_error_message)
      end
    end

    it 'raises error when only KUBECONFIG ENV variable is set' do
      with_modified_env KUBECONFIG: 'default_value' do
        expect { gke }.to raise_error(ArgumentError, env_error_message)
      end
    end

    context 'when both KUBECONFIG and GOOGLE_APPLICATION_CREDENTIALS ENV are set' do
      before do
        pass_through_initialization
      end

      it 'sets the hosts data member accordingly' do
        expect(gke.instance_variable_get(:@hosts)).to equal(hosts)
      end

      it 'sets the options data member accordingly' do
        expect(gke.instance_variable_get(:@options)).to equal(options)
      end

      it 'sets the logger data member accordingly' do
        expect(gke.instance_variable_get(:@logger)).to equal(logger)
      end

      it 'succeeds and does not raise any errors' do
        expect { gke }.not_to raise_error
      end
    end
  end

  describe ' #provision' do
    let(:pod) { instance_double('pod') }

    let(:status) { instance_double('status', podIP: '10.236.246.250') }
    let(:empty_ip_status) { instance_double('status', podIP: nil) }

    def pass_through_pod_and_service_creation
      allow(gke).to receive(:create_pod).and_return(nil)
      allow(gke).to receive(:read_file).with('pod.yaml').and_return('pod.yaml content')

      allow(gke).to receive(:create_srv).and_return(nil)
      allow(gke).to receive(:read_file).with('service.yaml').and_return('service.yaml content')
    end

    before do
      pass_through_initialization
      pass_through_pod_and_service_creation
      allow(gke).to receive(:sleep).and_return(true)
    end

    context 'when no hosts given' do
      let(:no_hosts_gke) { ::Beaker::Gke.new([], options) }

      it 'returns nil' do
        expect(no_hosts_gke.provision).to eq(nil)
      end

      it 'logs no info' do
        no_hosts_gke.provision
        expect(logger).not_to have_received(:info)
      end

      it 'does not raise any error' do
        expect { no_hosts_gke.provision }.not_to raise_error
      end
    end

    it 'raises StandardError and logs podIP retrieval attempts' do # rubocop:disable RSpec/MultipleExpectations
      allow(gke).to receive(:get_pod).and_return(pod)
      allow(pod).to receive(:status).and_return(empty_ip_status)

      expect { gke.provision }.to raise_error(StandardError)
      expect(logger).to have_received(:info).with(/Retrying, could not get podIP for/).at_least(:once)
    end

    it 'succeeds' do
      allow(gke).to receive(:get_pod).and_return(pod)
      allow(pod).to receive(:status).and_return(status)

      expect(gke.provision).to eq(nil)
    end
  end

  describe ' #cleanup' do
    before do
      pass_through_initialization
    end

    context 'when no hosts given' do
      let(:no_hosts_gke) { ::Beaker::Gke.new([], options) }

      it 'does not raise any error' do
        expect { no_hosts_gke.cleanup }.not_to raise_error
      end

      it 'logs no info' do
        no_hosts_gke.cleanup
        expect(logger).not_to have_received(:info)
      end
    end

    context 'when succeeds' do
      before do
        allow(gke).to receive(:delete_pod).and_return(nil)
        allow(gke).to receive(:delete_service).and_return(nil)
      end

      it 'does not raise any error' do
        expect { gke.cleanup }.not_to raise_error
      end

      it 'logs deleted pods' do
        gke.cleanup
        expect(logger).to have_received(:info).with(/Deleting POD with ID:/).exactly(hosts.size).times
      end
    end
  end
end
