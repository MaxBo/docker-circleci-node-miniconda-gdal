FROM circleci/python:3.6-stretch-node-browsers

ENV CIRCLECIPATH $PATH

USER root

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN apt-get update --fix-missing && \
    apt-get install -y apt-utils && \
    apt-get install -y software-properties-common && \
    apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion

RUN echo "Installing GDAL 2..." && \
    apt-get install -y python3-gdal python3-pyproj binutils libproj-dev gdal-bin libgdal-dev libgeos-dev


RUN apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean

RUN apt-key adv --keyserver keys.openpgp.org --recv-key 612DEFB798507F25 && \
    add-apt-repository "deb [ arch=amd64 ] https://downloads.skewed.de/apt $(lsb_release -cs) main" && \
    apt-get update && \
    apt-get install -y --allow-unauthenticated python3-graph-tool && \
    apt-get install -y --allow-unauthenticated libcairo2-dev libjpeg-dev libgif-dev libgirepository1.0-dev

# there appeared a dependency conflict when installing gtk3.0 in Debian stretch, so we skip this here.
# RUN apt-get install -y --allow-unauthenticated gtk+3.0

RUN apt-get install -y sqlite3 libsqlite3-mod-spatialite spatialite-bin

RUN apt-get install -y vim

RUN apt-get install -y libpq-dev 

RUN apt-get install -y gettext imagemagick ghostscript

RUN sed -i -e '/pattern\=\"PDF\"/s/\(^.*$\)/<!--\1-->/' /etc/ImageMagick-6/policy.xml

RUN chown -R circleci /usr/local
USER circleci


RUN cd /home/circleci && \
    git clone https://github.com/MaxBo/REPAiR-Web.git repairweb && \
    cd repairweb && \
    python -m pip install --upgrade pip && \
	pip install scipy && \
    pip install pycairo && \
    pip install pygobject

RUN cd /home/circleci/repairweb && \
    pip install -r requirements-dev.txt
RUN export GDALVERSION=$(gdalinfo --version | awk -F'[, ]' '{print $2}') && pip install pygdal==$GDALVERSION.*

RUN export dp=/usr/lib/python3/dist-packages && \
    ln -s $dp/graph_tool  $dp/gdal* /usr/local/lib/python3.6/site-packages/

RUN export ul=/usr/lib && \
    ln -s $ul/libgdal.so $ul/libblas.so $ul/liblapack.so $ul/libcgraph.so /usr/local/lib/ 

RUN export lg=/usr/lib/x86_64-linux-gnu && \
    ln -s $lg/libgeos_c.so  $lg/libgeotiff.so $lg/libxml2.so $lg/libtiff.so $lg/libpng.so $lg/mod_spatialite.so $lg/libspatialite.so $lg/libsqlite3.so $lg/libproj.so $lg/libpq.so /usr/local/lib/


ENV GDAL_DATA /usr/share/gdal/2.1
