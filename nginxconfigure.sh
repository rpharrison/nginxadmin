#!/bin/sh

CUSTOMSERVERNAME='y'
CUSTOMSERVERSTRING='nginx admin'

HN=$(uname -n)

if [ -f /proc/user_beancounters ]; then
    # CPUS='1'
    # MAKETHREADS=" -j$CPUS"
    # speed up make
    CPUS=`cat "/proc/cpuinfo" | grep "processor"|wc -l`
    CPUS=$(echo $CPUS+1 | bc)
    MAKETHREADS=" -j$CPUS"
else
    # speed up make
    CPUS=`cat "/proc/cpuinfo" | grep "processor"|wc -l`
    CPUS=$(echo $CPUS+1 | bc)
    MAKETHREADS=" -j$CPUS"
fi

# compiler related
CLANG='y'                     # Nginx and LibreSSL
STRIPNGINX='y'               # set 'y' to strip nginx binary to reduce size
NGINX_HTTP2=y                # Nginx http/2 patch https://community.centminmod.com/threads/4127/
NGINX_SPDY=n                 # Nginx SPDY support
NGINX_FLV=y                  # http://nginx.org/en/docs/http/ngx_http_flv_module.html
NGINX_MP4=y                  # Nginx MP4 Module http://nginx.org/en/docs/http/ngx_http_mp4_module.html
NGINX_VHOSTSTATS=y           # https://github.com/vozlt/nginx-module-vts
NGINX_PCREJIT=y              # Nginx configured with pcre & pcre-jit support
NGINX_PCREVER='8.37'         # Version of PCRE used for pcre-jit support in Nginx

##################################
## Nginx SSL options
# OpenSSL
NOSOURCEOPENSSL='y'        # set to 'y' to disable OpenSSL source compile for system default YUM package setup
OPENSSL_VERSION='1.0.2d'   # Use this version of OpenSSL http://openssl.org/
CLOUDFLARE_PATCHSSL='n'    # set 'y' to implement Cloudflare's kill RC4 patch https://github.com/cloudflare/sslconfig

# LibreSSL
LIBRESSL_SWITCH='y'        # if set to 'y' it overrides OpenSSL as the default static compiled option for Nginx server
LIBRESSL_VERSION='2.2.4'   # Use this version of LibreSSL http://www.libressl.org/
##################################

function funct_nginxconfigure {

if [[ "$CENTOSVER" = '6.0' || "$CENTOSVER" = '6.1' || "$CENTOSVER" = '6.2' || "$CENTOSVER" = '6.3' || "$CENTOSVER" = '6.4' || "$CENTOSVER" = '6.5' || "$CENTOSVER" = '6.6' || "$CENTOSVER" = '6.7' || "$CENTOSVER" = '6.8' || "$CENTOSVER" = '6.9' || "$CENTOSVER" = '7.0' || "$CENTOSVER" = '7.1' || "$CENTOSVER" = '7.2' || "$CENTOSVER" = '7.3' || "$CENTOSVER" = '7.4' || "$CENTOSVER" = '7.5' || "$CENTOSVER" = '7.6' || "$CENTOSVER" = '7.7' ]]; then

	if [[ "$NGINX_HTTP2" = [yY] ]]; then	
			NGINX_SPDY=n		
			HTTPTWOOPT=' --with-http_v2_module'
		fi
	else
		HTTPTWOOPT=""
	fi

	if [[ "$LIBRESSL_SWITCH" = [yY] ]]; then
		LIBRESSLOPT=" --with-openssl=../libressl-${LIBRESSL_VERSION}"
		OPENSSLOPT=""
		LRT='-lrt '
	else
		if [ "$NOSOURCEOPENSSL" == 'n' ]; then
			LIBRESSLOPT=""
			OPENSSLOPT=" --with-openssl=../openssl-${OPENSSL_VERSION}"
			LRT=""
		else
			export BPATH=$DIR_TMP
			export STATICLIBSSL="${BPATH}/staticlibssl"
			LIBRESSLOPT=""
			OPENSSLOPT=" --with-openssl=../openssl-${OPENSSL_VERSION}"
			LRT=""
		fi
	fi

	if [[ "$NGINX_SPDY" = [yY] ]]; then
		SPDYOPT=" --with-http_spdy_module"
		HTTPTWOOPT=""
	else
		SPDYOPT=""
	fi
	if [[ "$NGINX_FLV" = [yY] ]]; then
		FLVOPT=" --with-http_flv_module"
	else
		FLVOPT=""
	fi	
	if [[ "$NGINX_MP4" = [yY] ]]; then
		MPOPT=" --with-http_mp4_module"
	else
		MPOPT=""
	fi		
	
	if [[ "$NGINX_VHOSTSTATS" = [yY] ]]; then
		if [ -f /usr/bin/git ]; then
			VTSOPT=" --add-module=../nginx-module-vts"
			if [[ ! -d "${DIR_TMP}/nginx-module-vts" ]]; then
				cd $DIR_TMP
				git clone $NGX_VTSLINK nginx-module-vts
				# sed -i 's|color:       black;|color:       white;|g' ${DIR_TMP}/nginx-module-vts/share/status.template.html
				sed -i 's|#DED|#43a6df|g' ${DIR_TMP}/nginx-module-vts/share/status.template.html
				# sed -i 's|color:       black;|color:       white;|g' ${DIR_TMP}/nginx-module-vts/share/status.compress.html
				sed -i 's|#DED|#43a6df|g' ${DIR_TMP}/nginx-module-vts/share/status.compress.html
				cd nginx-module-vts/util
				./tplToDefine.sh ../share/status.template.html > ../src/ngx_http_vhost_traffic_status_module_html.h
				# ./tplToDefine.sh ../share/status.compress.html > ../src/ngx_http_vhost_traffic_status_module_html.h
				cd ../
				# setup /vhost_status.html
				cp -a ${DIR_TMP}/nginx-module-vts/share/status.compress.html /usr/local/nginx/html/vhost_status.html
				MAINURIHOST=$HN
				NEWURI="//${MAINURIHOST}/vhost_status"
				if [ -f /usr/local/nginx/html/vhost_status.html ]; then
					sed -i "s|{{uri}}|$NEWURI|" /usr/local/nginx/html/vhost_status.html
				fi
			elif [[ -d "${DIR_TMP}/nginx-module-vts" && -d "${DIR_TMP}/nginx-module-vts/.git" ]]; then
				cd ${DIR_TMP}/nginx-module-vts
				git stash
				git pull
				# sed -i 's|color:       black;|color:       white;|g' ${DIR_TMP}/nginx-module-vts/share/status.template.html
				sed -i 's|#DED|#43a6df|g' ${DIR_TMP}/nginx-module-vts/share/status.template.html
				# sed -i 's|color:       black;|color:       white;|g' ${DIR_TMP}/nginx-module-vts/share/status.compress.html
				sed -i 's|#DED|#43a6df|g' ${DIR_TMP}/nginx-module-vts/share/status.compress.html
				cd nginx-module-vts/util
				./tplToDefine.sh ../share/status.template.html > ../src/ngx_http_vhost_traffic_status_module_html.h
				# ./tplToDefine.sh ../share/status.compress.html > ../src/ngx_http_vhost_traffic_status_module_html.h
				cd ../
				# setup /vhost_status.html
				cp -a ${DIR_TMP}/nginx-module-vts/share/status.compress.html /usr/local/nginx/html/vhost_status.html
				MAINURIHOST=$HN
				NEWURI="//${MAINURIHOST}/vhost_status"
				if [ -f /usr/local/nginx/html/vhost_status.html ]; then
					sed -i "s|{{uri}}|$NEWURI|" /usr/local/nginx/html/vhost_status.html
				fi
			fi
		else
			VTSOPT=""
		fi
	else
		VTSOPT=""
	fi
	if [[ "$NGINX_PCREJIT" = [yY] ]]; then
		PCREJITOPT=" --with-pcre=../pcre-${NGINX_PCREVER} --with-pcre-jit"
	else
		PCREJITOPT=""
	fi
else
	if [[ "$NGINX_HTTP2" = [yY] ]]; then	
		# only apply Nginx HTTP/2 if Nginx version is >= 1.9.3 and <1.9.5 OR >= 1.9.5
		if [[ "$NGX_VEREVAL" -ge '10903' && "$NGX_VEREVAL" -lt '10905' ]] || [[ "$NGX_VEREVAL" -ge '10905' ]]; then
			NGINX_SPDY=n		
			HTTPTWOOPT=' --with-http_v2_module'
		fi
	else
		HTTPTWOOPT=""
		if [[ "$NGX_VEREVAL" -lt '10903' ]]; then
			NGINX_SPDY=y
		fi		
	fi
	if [[ "$LIBRESSL_SWITCH" = [yY] ]]; then
		LIBRESSLOPT=" --with-openssl=../libressl-${LIBRESSL_VERSION}"
		OPENSSLOPT=""
		LRT='-lrt '
	else
		LIBRESSLOPT=""
		OPENSSLOPT=" --with-openssl=../openssl-${OPENSSL_VERSION}"
		LRT=""
	fi
	if [[ "$NGINX_SPDY" = [yY] ]]; then
		SPDYOPT=" --with-http_spdy_module"
	else
		SPDYOPT=""
	fi	
	if [[ "$NGINX_FLV" = [yY] ]]; then
		FLVOPT=" --with-http_flv_module"
	else
		FLVOPT=""
	fi		
	if [[ "$NGINX_MP4" = [yY] ]]; then
		MPOPT=" --with-http_mp4_module"
	else
		MPOPT=""
	fi
	if [[ "$NGINX_PCREJIT" = [yY] ]]; then
		PCREJITOPT=""
	else
		PCREJITOPT=""
	fi
fi
# disable Clang compiler for Nginx if NGINX_PASSENGER=y as Clang fails
# to compile Passenger Nginx Module while GCC compiler works
if [[ "$NGINX_PASSENGER" = [yY] ]]; then
	CLANG='n'
fi
if [[ -d "${DIR_TMP}/nginx-${NGINX_VERSION}" && ! "$ngver" ]]; then
	cd ${DIR_TMP}/nginx-${NGINX_VERSION}
fi
if [[ -d "${DIR_TMP}/nginx-${ngver}" && "$ngver" ]]; then
	cd ${DIR_TMP}/nginx-${ngver}
fi
if [ -f src/http/ngx_http_header_filter_module.c ]; then
	if [[ "$CUSTOMSERVERNAME" == [yY] ]]; then
		echo ""
		echo "Check existing server string:"
	grep "Server: " src/http/ngx_http_header_filter_module.c | grep -v full_string
		echo ""
		echo "Change server string to $CUSTOMSERVERSTRING"
	sed -i "s/Server: nginx/Server: $CUSTOMSERVERSTRING/g" src/http/ngx_http_header_filter_module.c
		echo ""
	fi
fi
if [[ ! -f /usr/bin/jemalloc.sh || ! -d /usr/include/jemalloc ]]; then
	yum -y install jemalloc jemalloc-devel
fi
# NGINX 1.9 stream support & 1.8 threads
# http://nginx.org/en/docs/stream/ngx_stream_core_module.html
NGXINSTALL_VER=$(echo $NGINX_VERSION | cut -d . -f1,2)
NGXUPGRADE_VER=$(echo $ngver | cut -d . -f1,2)
if [[ "$ngver" && "$NGXUPGRADE_VER" = '1.9' ]]; then
	if [[ "$NGINX_STREAM" = [yY] ]]; then
		STREAM=' --with-stream --with-stream_ssl_module'
	else
		STREAM=""
	fi
	THREADS=' --with-threads'
	# workaround for nginx 1.9 compatibility
	# sed -i.bak 's|ngx_http_set_connection_log|ngx_set_connection_log|g' ${DIR_TMP}/lua-nginx-module-${ORESTY_LUANGINXVER}/src/ngx_http_lua_initworkerby.c
	# sed -i.bak 's|ngx_http_set_connection_log|ngx_set_connection_log|g' ${DIR_TMP}/lua-nginx-module-${ORESTY_LUANGINXVER}/src/ngx_http_lua_timer.c
elif [[ -z "$ngver" && "$NGXINSTALL_VER" = '1.9' ]]; then
	if [[ "$NGINX_STREAM" = [yY] ]]; then
		STREAM=' --with-stream --with-stream_ssl_module'
	else
		STREAM=""
	fi
	THREADS=' --with-threads'
	# workaround for nginx 1.9 compatibility
	# sed -i.bak 's|ngx_http_set_connection_log|ngx_set_connection_log|g' ${DIR_TMP}/lua-nginx-module-${ORESTY_LUANGINXVER}/src/ngx_http_lua_initworkerby.c
	# sed -i.bak 's|ngx_http_set_connection_log|ngx_set_connection_log|g' ${DIR_TMP}/lua-nginx-module-${ORESTY_LUANGINXVER}/src/ngx_http_lua_timer.c	
elif [[ "$ngver" && "$NGXUPGRADE_VER" = '1.8' ]]; then
	STREAM=""
	THREADS=' --with-threads'
elif [[ -z "$ngver" && "$NGXINSTALL_VER" = '1.8' ]]; then
	STREAM=""
	THREADS=' --with-threads'	
else
	STREAM=""
	THREADS=""
fi
# intel specific
CPUVENDOR=$(cat /proc/cpuinfo | awk '/vendor_id/ {print $3}' | sort -u | head -n1)
gcc -c -Q -march=native --help=target | egrep '\[enabled\]|mtune|march' | tee ${CENTMINLOGDIR}/gcc_native.log
if [[ "$(uname -m)" = 'x86_64' && "$CPUVENDOR" = 'GenuineIntel' ]]; then
	CCM=64
	MTUNEOPT="-m${CCM} -mtune=native "
elif [[ "$(uname -m)" != 'x86_64' && "$CPUVENDOR" = 'GenuineIntel' ]]; then
	CCM=32
	MTUNEOPT="-m${CCM} -mtune=generic "
else
	MTUNEOPT=""
fi
if [[ "$CLANG" = [yY] ]]; then
	if [[ ! -f /usr/bin/clang ]]; then
		yum -q -y install clang clang-devel
	fi
	# ccache compiler has some initial overhead for compiles but speeds up subsequent
	# recompiles. however on initial install ccache has no benefits, so for initial
	# centmin mod install disabling ccache will in theory speed up first time installs
	if [[ "$INITIALINSTALL" != [yY] ]]; then	
		export CC="ccache /usr/bin/clang -ferror-limit=0"
		export CXX="ccache /usr/bin/clang++ -ferror-limit=0"
		export CCACHE_CPP2=yes
		CLANG_CCOPT=' -Wno-deprecated-declarations -Wno-unused-parameter -Wno-unused-const-variable -Wno-conditional-uninitialized -Wno-mismatched-tags -Wno-c++11-extensions -Wno-sometimes-uninitialized -Wno-parentheses-equality -Wno-tautological-compare -Wno-self-assign -Wno-deprecated-register -Wno-deprecated -Wno-invalid-source-encoding -Wno-pointer-sign -Wno-parentheses -Wno-enum-conversion'
	else
		export CC="/usr/bin/clang -ferror-limit=0"
		export CXX="/usr/bin/clang++ -ferror-limit=0"
		# export CCACHE_CPP2=yes
		CLANG_CCOPT=' -Wno-deprecated-declarations -Wno-unused-parameter -Wno-unused-const-variable -Wno-conditional-uninitialized -Wno-mismatched-tags -Wno-c++11-extensions -Wno-sometimes-uninitialized -Wno-parentheses-equality -Wno-tautological-compare -Wno-self-assign -Wno-deprecated-register -Wno-deprecated -Wno-invalid-source-encoding -Wno-pointer-sign -Wno-parentheses -Wno-enum-conversion'
	fi
else
	CLANG_CCOPT=""
fi
#    ASK "Would you like to compile nginx with IPv6 support? [y/n] "
#    if [[ "$asknginxipv" = [yY] ]]; then
      if [[ "$asknginxipv" = [yY] || "$NGINX_IPV" = [yY] ]]; then
      	pwd
      	echo "nginx configure options:"
      	echo "./configure --with-ld-opt="${LRT}-ljemalloc -Wl,-z,relro${LUALD_OPT}" --with-cc-opt="${MTUNEOPT}-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2${CLANG_CCOPT}" --sbin-path=/usr/local/sbin --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-ipv6 --with-http_ssl_module${HTTPTWOOPT} --http-client-body-temp-path=/tmp/nginx_client --http-proxy-temp-path=/tmp/nginx_proxy --http-fastcgi-temp-path=/tmp/nginx_fastcgi --with-http_stub_status_module ${FLVOPT}${MPOPT} --with-http_realip_module --with-openssl-opt="enable-tlsext"${VTSOPT} ${OPENSSLOPT}${LIBRESSLOPT}${PCREJITOPT}${SPDYOPT}
		./configure --with-ld-opt="${LRT}-ljemalloc -Wl,-z,relro${LUALD_OPT}" --with-cc-opt="${MTUNEOPT}-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2${CLANG_CCOPT}" --sbin-path=/usr/local/sbin/nginx --conf-path=/usr/local/nginx/conf/nginx.conf${NGINX_DEBUGOPT} --with-ipv6 --with-http_ssl_module${HTTPTWOOPT} --with-http_stub_status_module --with-http_realip_module${GEOIPOPT} --with-openssl-opt="enable-tlsext"${VTSOPT} ${OPENSSLOPT}${LIBRESSLOPT}${PCREJITOPT}${SPDYOPT}
    else
    	pwd
    	echo "nginx configure options:"
    	echo "./configure --with-ld-opt="${LRT}-ljemalloc -Wl,-z,relro${LUALD_OPT}" --with-cc-opt="${MTUNEOPT}-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2${CLANG_CCOPT}" --sbin-path=/usr/local/sbin/nginx --conf-path=/usr/local/nginx/conf/nginx.conf --with-http_ssl_module${HTTPTWOOPT} --with-http_gzip_static_module --with-http_stub_status_module ${FLVOPT}${MPOPT} --with-http_realip_module --with-openssl-opt="enable-tlsext"${VTSOPT}${OPENSSLOPT}${LIBRESSLOPT}${PCREJITOPT}${SPDYOPT}
		./configure --with-ld-opt="${LRT}-ljemalloc -Wl,-z,relro${LUALD_OPT}" --with-cc-opt="${MTUNEOPT}-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2${CLANG_CCOPT}" --sbin-path=/usr/local/sbin/nginx --conf-path=/usr/local/nginx/conf/nginx.conf${NGINX_DEBUGOPT} --with-http_ssl_module${HTTPTWOOPT} --with-http_stub_status_module ${FLVOPT}${MPOPT} --with-http_realip_module --with-openssl-opt="enable-tlsext"${VTSOPT}{OPENSSLOPT}${LIBRESSLOPT}${PCREJITOPT}${SPDYOPT}
    fi   
}