require 'rubygems'
require 'ldap'

# sudo gem install ruby-ldap
# Returns realname from username
def ldap_realname(username)

  begin
    # Workaround for bug in jruby-ldap-0.0.1:
    LDAP::load_configuration()
  rescue

  end

  ldap_host = 'ldap.uio.no'
  conn = LDAP::Conn.new(ldap_host, LDAP::LDAP_PORT)
  filter = "(uid=#{username})";
  base_dn = "dc=uio,dc=no"

  if conn.bound? then
    conn.unbind()
  end

  ansatt = nil
  conn.bind do

    conn.search2("dc=uio,dc=no", LDAP::LDAP_SCOPE_SUBTREE,
                 "(uid=#{username})", nil, false, 0, 0).each do |entry|

      brukernavn = entry.to_hash["uid"][0]
      fornavn = entry.to_hash["givenName"][0]
      etternavn = entry.to_hash["sn"][0]
      # epost = entry.to_hash["mail"][0]
      # adresse = entry.to_hash["postalAddress"][0]

      return fornavn + " " + etternavn
    end
  end

end

def org_unit(id)

  require 'pp'

  begin
    # Workaround for bug in jruby-ldap-0.0.1:
    LDAP::load_configuration()
  rescue

  end

  ldap_host = 'ldap.uio.no'
  conn = LDAP::Conn.new(ldap_host, LDAP::LDAP_PORT)
  filter = "(ou=#{id})";
  base_dn = "dc=uio,dc=no"

  if conn.bound? then
    conn.unbind()
  end

  ansatt = nil
  conn.bind do

    # pp conn

    conn.search2("dc=uio,dc=no", LDAP::LDAP_SCOPE_SUBTREE,
                 "(ou=#{id})", nil, false, 0, 0).each do |entry|

      pp entry
      pp entry.to_hash
      return nil
      brukernavn = entry.to_hash["uid"][0]
      fornavn = entry.to_hash["givenName"][0]
      etternavn = entry.to_hash["sn"][0]
      # epost = entry.to_hash["mail"][0]
      # adresse = entry.to_hash["postalAddress"][0]

      return fornavn + " " + etternavn
    end
  end

end

org_unit("160000")

