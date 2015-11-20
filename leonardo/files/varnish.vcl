{%- set service = salt['pillar.get']('varnish:server:lookup:'+service_name) %}
#
# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and https://www.varnish-cache.org/trac/wiki/VCLExamples for more examples.

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;

# Default backend definition. Set this to point to your content server.
{%- for backend_name, backend in service.backend.iteritems() %}
backend {{ backend_name }} {
    .host = "{{ backend.host }}";
    .port = "{{ backend.port }}";
}
{%- endfor %}

sub identify_cookie {
    #Call cookie based detection method in vcl_recv.
    if (req.http.cookie ~ "sessionid=") {
           #unset all the cookie from request except language
            set req.http.sessionid = regsub(req.http.cookie, "(.*?)(sessionid=)([^;]*)(.*)$", "\3");
    }
    if (req.http.cookie ~ "csrftoken=") {
        set req.http.csrftoken = regsub(req.http.cookie, "(.*?)(csrftoken=)([^;]*)(.*)$", "\3");
    }
     # set req.http.Sessionid = False;    

}

sub vcl_hash {

    hash_data(req.url);
    if (req.http.host) {
       hash_data(req.http.host);
    } else {
       hash_data(server.ip);
    }

    if (req.http.sessionid) {
        #add cookie in hash
       hash_data(req.http.sessionid);
        #unset req.http.Cookie;
    }
    if (req.http.csrftoken) {
        hash_data(req.http.csrftoken);
    }
}

sub vcl_recv {
    # Happens before we check if we have this in cache already.
    #
    # Typically you clean up the request here, removing cookies you don't need,
    # rewriting the request, etc.

    #set req.http.X-Forwarded-For = client.ip;
    {%- for backend_name, backend in service.backend.iteritems() %}
    # TODO: use cluster
    set req.backend_hint = {{ backend_name }};
    {%- endfor %}

if (req.http.Cookie) {
    set req.http.Cookie = ";" + req.http.Cookie;
    set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
    set req.http.Cookie = regsuball(req.http.Cookie, ";(sessionid|csrftoken)=", "; \1=");
    set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");

    if (req.http.Cookie == "") {
        unset req.http.Cookie;
    }

    call identify_cookie;

}
    #set req.http.X-Forwarded-For = req.http.Sessionid;
    #if (!req.http.csrftoken){
    #    unset req.http.Cookie;
    #    return(hash);
    #}
    #set req.http.Test = "Test";

 set req.http.X-Session-ID = req.http.csrftoken;

 # You have one of two options when doing this
 # 1) Tell varnish to (fetch) the request even though it has a cookie. By default if a request has a cookie varnish will (pass).
# return (fetch);
 # 2) Strip the cookie and configure the backend to look for X-Session-ID. This way varnish by default will (fetch) the request.
#return(hash); 
if (req.method == "GET") {

#unset req.http.cookie;
return(hash);
}
}

sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    #
    # Here you clean the response headers, removing silly Set-Cookie headers
    # and other mistakes your backend does.

 if (bereq.url ~ "\.(png|gif|jpg|swf|css|scss|svg|js)$") {
    unset beresp.http.set-cookie;
 }

    set beresp.grace = 4h;
    set beresp.ttl = 5m;
    #unset beresp.http.Vary;
    set beresp.http.Vary = "Accept-Encoding";
    #et beresp.http.X-Cookie-Debug = "Request cookie: " req.http.Cookie;

if (!bereq.http.csrftoken) {
    #unset beresp.http.Set-Cookie;
} else {

}
    #unset beresp.http.Set-Cookie;
    set beresp.http.sessionid = bereq.http.sessionid;
    set beresp.http.Picka = bereq.http.csrftoken;
 #   set beresp.http.Set-Cookie = bereq.http.Cookie;

# Backend only sends vuserhash cookie for HTML responses
# We have to use the "header" Varnish module so that it can read multiple set-cookie headers

if( bereq.http.csrftoken ) {
 	# Check if client has invalid user hash value
 	# Comparing client cookie with server response cookie
 	if( regsub( beresp.http.Set-Cookie, ".*csrftoken=([^;]+).*", "\1" ) == regsub( bereq.http.cookie, ".*csrftoken=([^;]+).*", "\1" ) ) {
        set beresp.http.X-Cacheable = regsub( beresp.http.Set-Cookie, ".*csrftoken=([^;]+).*", "\1" );
        set beresp.http.X-Cacheable1 = regsub( bereq.http.cookie, ".*csrftoken=([^;]+).*", "\1" );
 	#std.syslog(180, "VARNISH: Invalid cookie found." );
        unset beresp.http.Set-Cookie;
       }

}


}

sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
    #
    # You can do accounting or modifying the final object here.
}
