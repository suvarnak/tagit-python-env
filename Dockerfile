FROM debian:latest
CMD ["bash"]
RUN apt-get update  \
	&& apt-get install -y --no-install-recommends ca-certificates curl netbase wget  \
	&& rm -rf /var/lib/apt/lists/*
RUN set -ex; if ! command -v gpg > /dev/null; then apt-get update; apt-get install -y --no-install-recommends gnupg dirmngr ; rm -rf /var/lib/apt/lists/*; fi
RUN apt-get update  \
	&& apt-get install -y --no-install-recommends bzr git mercurial openssh-client subversion procps  \
	&& rm -rf /var/lib/apt/lists/*
RUN set -ex; apt-get update; apt-get install -y --no-install-recommends autoconf automake bzip2 dpkg-dev file g++ gcc imagemagick libbz2-dev libc6-dev libcurl4-openssl-dev libdb-dev libevent-dev libffi-dev libgdbm-dev libgeoip-dev libglib2.0-dev libgmp-dev libjpeg-dev libkrb5-dev liblzma-dev libmagickcore-dev libmagickwand-dev libncurses5-dev libncursesw5-dev libpng-dev libpq-dev libreadline-dev libsqlite3-dev libssl-dev libtool libwebp-dev libxml2-dev libxslt-dev libyaml-dev make patch unzip xz-utils zlib1g-dev $( if apt-cache show 'default-libmysqlclient-dev' 2>/dev/null | grep -q '^Version:'; then echo 'default-libmysqlclient-dev'; else echo 'libmysqlclient-dev'; fi ) ; rm -rf /var/lib/apt/lists/*
ENV PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG=C.UTF-8
RUN apt-get update  \
	&& apt-get install -y --no-install-recommends tk-dev  \
	&& rm -rf /var/lib/apt/lists/*
ENV GPG_KEY=0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
ENV PYTHON_VERSION=3.6.8
RUN set -ex  \
	&& wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz"  \
	&& wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc"  \
	&& export GNUPGHOME="$(mktemp -d)"  \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$GPG_KEY"  \
	&& { command -v gpgconf > /dev/null  \
	&& gpgconf --kill all || :; }  \
	&& rm -rf "$GNUPGHOME" python.tar.xz.asc  \
	&& mkdir -p /usr/src/python  \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz  \
	&& rm python.tar.xz  \
	&& cd /usr/src/python  \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"  \
	&& ./configure --build="$gnuArch" --enable-loadable-sqlite-extensions --enable-shared --with-system-expat --with-system-ffi --without-ensurepip  \
	&& make -j "$(nproc)"  \
	&& make install  \
	&& ldconfig  \
	&& find /usr/local -depth \( \( -type d -a \( -name test -o -name tests \) \) -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \) -exec rm -rf '{}' +  \
	&& rm -rf /usr/src/python  \
	&& python3 --version
RUN cd /usr/local/bin  \
	&& ln -s idle3 idle  \
	&& ln -s pydoc3 pydoc  \
	&& ln -s python3 python  \
	&& ln -s python3-config python-config
ENV PYTHON_PIP_VERSION=19.0.3
RUN set -ex; wget -O get-pip.py 'https://bootstrap.pypa.io/pip/3.6/get-pip.py'; python get-pip.py --disable-pip-version-check --no-cache-dir "pip==$PYTHON_PIP_VERSION" ; pip --version; find /usr/local -depth \( \( -type d -a \( -name test -o -name tests \) \) -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \) -exec rm -rf '{}' +; rm -f get-pip.py
CMD ["python3"]
WORKDIR /workspace/
COPY requirements.txt /workspace/requirements.txt

RUN pip install -r requirements.txt  \
	&& pip install gunicorn[eventlet]==19.9.0  \
	&& pip install pycocotools
RUN git clone --single-branch --depth 1 https://github.com/matterport/Mask_RCNN.git /tmp/maskrcnn  \
	&& cd /tmp/maskrcnn  \
	&& pip install protobuf==3.19.6 && pip3 install -r requirements.txt  \
	&& python3 setup.py install
RUN git clone https://github.com/scaelles/DEXTR-KerasTensorflow.git /tmp/dextr  \
	&& cd /tmp/dextr  \
    && cd models/ \
    && chmod +x download_dextr_model.sh \
    && ./download_dextr_model.sh \
    && cd ..

