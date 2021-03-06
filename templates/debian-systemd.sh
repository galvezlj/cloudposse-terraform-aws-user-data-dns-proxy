
##############
# Install deps
##############
apt-get update
apt-get -y install bind9

##
## Makefile for dns proxy zones
##
cat <<"__EOF__" > /etc/bind/named.conf.default-zones
// prime the server with knowledge of the root servers
zone "." {
        type hint;
        file "/etc/bind/db.root";
};

// be authoritative for the localhost forward and reverse zones, and for
// broadcast zones as per RFC 1912

zone "localhost" {
        type master;
        file "/etc/bind/db.local";
};

zone "${domain}" {
        type forward;
        forward first;
        forwarders  { ${ip}; };
};

zone "${region}.amazonaws.com" {
        type forward;
        forward first;
        forwarders  { 10.0.0.2; };
};
__EOF__
chmod 644 /etc/bind/named.conf.default-zones


##
## Makefile for dns proxy options
##
cat <<"__EOF__" > /etc/bind/named.conf.options
options {
        directory "/var/cache/bind";

        dnssec-validation auto;

        auth-nxdomain no;    # conform to RFC1035
        listen-on-v6 { any; };

        recursion yes;                 # enables resursive queries
        allow-recursion { trusted; };  # allows recursive queries from "trusted" clients
        listen-on { any; };            # ns1 private IP address - listen on private network only
        allow-transfer { none; };      # disable zone transfers by default

        forwarders {
                8.8.8.8;
                8.8.4.4;
                10.0.0.2;
                ${ip};
        };
};


acl "trusted" {
       any;
};
__EOF__
chmod 644 /etc/bind/named.conf.options

##
## Makefile for bind defaults
##
cat <<"__EOF__" > /etc/default/bind9
# run resolvconf?
RESOLVCONF=no

# startup options for the server
OPTIONS="-u bind -4"
__EOF__
chmod 644 /etc/default/bind9


service bind9 restart