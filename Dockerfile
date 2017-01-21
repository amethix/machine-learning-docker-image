
FROM jupyter/base-notebook:latest

MAINTAINER Eyad Sibai <eyad.alsibai@gmail.com>

USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y  --no-install-recommends git libav-tools cmake build-essential \
libopenblas-dev libopencv-dev libboost-program-options-dev zlib1g-dev libboost-python-dev unzip \
&& apt-get autoremove -y && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER $NB_USER

RUN conda config --add channels conda-forge --add channels glemaitre && conda config --set channel_priority false
COPY files/environment.yaml environment.yaml
COPY files/ipython_config.py $HOME/.ipython/profile_default/ipython_config.py
RUN conda env update --file=environment.yaml --quiet \
    && conda remove qt pyqt --quiet --yes --force \
    && conda clean -i -l -t -y && rm -rf "$HOME/.cache/pip/*" && rm environment.yaml

# install packages without their dependencies
RUN pip install --no-cache-dir rep git+https://github.com/googledatalab/pydatalab.git --no-deps \
&& rm -rf "$HOME/.cache/pip/*"


RUN mkdir $HOME/bin
RUN git clone https://github.com/facebookresearch/fastText.git && cd fastText && make && mv fasttext $HOME/bin && cd .. \
&& rm -rf fastText

# Regularized Greedy Forests
RUN wget https://github.com/fukatani/rgf_python/releases/download/0.2.0/rgf1.2.zip && \
    unzip rgf1.2.zip && cd rgf1.2 && make && mv bin/rgf $HOME/bin && cd .. && rm -rf rgf*

# LightGBM
RUN git clone --recursive https://github.com/Microsoft/LightGBM && \
    cd LightGBM && mkdir build && cd build && cmake .. && make -j $(nproc) && \
        cd ../python-package && python setup.py install && cd ../.. && rm -rf LightGBM

# Vowpal wabbit
#git clone https://github.com/JohnLangford/vowpal_wabbit.git && \
#cd vowpal_wabbit && \
#make && \
#make install

# MXNet
#RUN git clone --recursive https://github.com/dmlc/mxnet && \
#    cd mxnet && cp make/config.mk . && echo "USE_BLAS=openblas" >> config.mk && \
#    make && cd python && python setup.py install && cd ../../ && rm -rf mxnet


# Run Torch7 installation scripts
# RUN git clone https://github.com/torch/distro.git $HOME/torch --recursive && cd $HOME/torch && bash install-deps && \
 # ./install.sh

# Export environment variables manually
#ENV LUA_PATH='/root/.luarocks/share/lua/5.1/?.lua;/root/.luarocks/share/lua/5.1/?/init.lua;/root/torch/install/share/lua/5.1/?.lua;/root/torch/install/share/lua/5.1/?/init.lua;./?.lua;/root/torch/install/share/luajit-2.1.0-beta1/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua'
#ENV LUA_CPATH='/root/.luarocks/lib/lua/5.1/?.so;/root/torch/install/lib/lua/5.1/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so'
#ENV PATH=/root/torch/install/bin:$PATH
#ENV LD_LIBRARY_PATH=/root/torch/install/lib:$LD_LIBRARY_PATH
#ENV DYLD_LIBRARY_PATH=/root/torch/install/lib:$DYLD_LIBRARY_PATH
#ENV LUA_CPATH='/root/torch/install/lib/?.so;'$LUA_CPATH

# Activate ipywidgets extension in the environment that runs the notebook server
# Required to display Altair charts in Jupyter notebook
RUN jupyter nbextension enable --py widgetsnbextension --sys-prefix && \
python -m jupyterdrive --mixed --user

RUN mkdir -p $HOME/.config/matplotlib && echo 'backend: agg' > $HOME/.config/matplotlib/matplotlibrc

# tensorflow board
EXPOSE 6006

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME /home/$NB_USER/.cache/g
ENV PATH $HOME/bin:$PATH

RUN python -m nltk.downloader abc alpino \
    averaged_perceptron_tagger basque_grammars biocreative_ppi bllip_wsj_no_aux \
    book_grammars brown brown_tei cess_cat cess_esp chat80 city_database cmudict \
    comparative_sentences comtrans conll2000 conll2002 conll2007 crubadan dependency_treebank \
    europarl_raw floresta gazetteers genesis gutenberg hmm_treebank_pos_tagger \
    ieer inaugural indian jeita kimmo knbc large_grammars lin_thesaurus mac_morpho machado \
    masc_tagged maxent_ne_chunker maxent_treebank_pos_tagger moses_sample movie_reviews \
    mte_teip5 names nps_chat omw opinion_lexicon paradigms \
    pil pl196x ppattach problem_reports product_reviews_1 product_reviews_2 propbank \
    pros_cons ptb punkt qc reuters rslp rte sample_grammars semcor sentence_polarity \
    sentiwordnet shakespeare sinica_treebank smultron snowball_data spanish_grammars \
    state_union stopwords subjectivity swadesh switchboard tagsets timit toolbox treebank \
    twitter_samples udhr2 udhr unicode_samples universal_tagset universal_treebanks_v20 \
    vader_lexicon verbnet webtext word2vec_sample wordnet wordnet_ic words ycoe \
    && find $HOME/nltk_data -type f -name "*.zip" -delete
RUN python -m spacy.en.download
RUN python -m textblob.download_corpora
