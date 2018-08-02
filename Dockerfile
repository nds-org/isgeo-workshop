FROM jupyter/scipy-notebook:5811dcb711ba

RUN conda install -y -q -c anaconda -c conda-forge \
        basemap \
        cartopy \
        folium \
        geopandas \
        netcdf4 \
        nb_conda_kernels \
        pydap \
        pydrive \
        r \
        r-irkernel \
        r-recommended \
        r-essentials \
        shapely \
        xarray \
        xlsxwriter && \
   conda install --quiet --yes \
        'ipyleaflet=0.9.0' \
        'altair=2.1.0' \
        'vega_datasets=0.5.0' \
        'bqplot=0.10.5' \
        'nbdime=1.0.1' \
        'palettable=3.1.1' \
        'earthengine-api=0.1.143' \
      && \
    conda clean -tipsy && \
    jupyter nbextension enable --py widgetsnbextension --sys-prefix && \
    jupyter labextension install --no-build jupyter-leaflet@0.9.0 && \
    jupyter labextension install --no-build @jupyter-widgets/jupyterlab-manager@0.35 && \
    jupyter labextension install --no-build bqplot && \
    jupyter labextension install --no-build jupyterlab-toc && \
    jupyter lab build && \
    pip install hone tables h5pyd && \
    npm cache clean --force && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    rm -rf /home/$NB_USER/.node-gyp && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER
