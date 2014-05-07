require 'metasploit/framework/login_scanner/base'
require 'postgres_msf'

module Metasploit
  module Framework
    module LoginScanner

      # This is the LoginScanner class for dealing with PostgreSQL database servers.
      # It is responsible for taking a single target, and a list of credentials
      # and attempting them. It then saves the results.
      class Postgres
        include Metasploit::Framework::LoginScanner::Base

        # This method attempts a single login with a single credential against the target
        # @param credential [Credential] The credential object to attmpt to login with
        # @return [Metasploit::Framework::LoginScanner::Result] The LoginScanner Result object
        def attempt_login(credential)
          result_options = {
              credential: credential
          }

          db_name = credential.realm || 'template1'

          if ::Rex::Socket.is_ipv6?(host)
            uri = "tcp://[#{host}]:#{port}"
          else
            uri = "tcp://#{host}:#{port}"
          end

          pg_conn = nil

          begin
            pg_conn = Msf::Db::PostgresPR::Connection.new(db_name,credential.public,credential.private,uri)
          rescue RuntimeError => e
            case e.to_s.split("\t")[1]
              when "C3D000"
                result_options.merge!({
                  status: :failed,
                  proof: "C3D000, Creds were good but database was bad"
                })
              when "C28000", "C28P01"
                result_options.merge!({
                    status: :failed,
                    proof: "Invalid username or password"
                })
              else
                result_options.merge!({
                    status: :failed,
                    proof: e.message
                })
            end
          end

          if pg_conn
            pg_conn.close
            result_options[:status] = :success
          else
            result_options[:status] = :failed
          end

          ::Metasploit::Framework::LoginScanner::Result.new(result_options)

        end


      end


    end
  end
end