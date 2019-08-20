#see https://github.com/jupyter/jupyter_server/tree/master/jupyter_server
# see https://docs.openshift.com/container-platform/3.11/using_images/s2i_images/python.html
oc get dc || echo "FAILED: could not verify connection to Openshift"

oc new-build --image-stream=openshift/python --code='https://github.com/jupyter/notebook.git' --context-dir='notebook'


oc new-build --name=notebook-1 openshift/python~https://github.com/jupyter/notebook.git --context-dir='notebook'

oc new-build --name=notebook-2 openshift/python~https://github.com/jupyter/notebook.git





oc new-build --name=notebook-2a --image-stream=openshift/python --code='https://github.com/jupyter/notebook.git'
oc new-build --name=notebook-build-step-2b \
             --image-stream=notebook-2a \
             --to=jupyter-notebook-custom \
             --code='https://github.com/michaelepley/openshift-templates.git' \
             --strategy=docker \
             --dockerfile=$'FROM scratch\nENV APP_SCRIPT="/opt/app-root/bin/app.sh"\nRUN echo "/opt/app-root/bin/jupyter notebook" > /opt/app-root/bin/app.sh && chmod a+x /opt/app-root/bin/app.sh\nEXPOSE 8888'
             
             
             

oc new-app --image-stream=jupyter-notebook-custom



#oc new-build --name=notebook-3 openshift/python~https://github.com/jupyter/notebook.git --context-dir='notebook'

#oc new-app --image-stream=notebook-2

#oc new-app --image-stream=notebook-2 -e APP_SCRIPT="/opt/app-root/bin/jupyter notebook"
 
#oc delete all -l app=notebook-2





echo "Done."


exit

oc patch dc/notebook-2 -p '{"spec": {"template": {"spec": {"containers":[{"name":"notebook-2", "command": ["/bin/sleep", "infinity"]}]}}}}' 


oc get bc/${S2I_BASE_IMAGE_MODIFIED_ISOLATED}-build || oc new-build --name=${S2I_BASE_IMAGE_MODIFIED_ISOLATED}-build --image-stream=${S2I_BASE_IMAGE} --to=${S2I_BASE_IMAGE_MODIFIED_ISOLATED} --code='https://github.com/michaelepley/openshift-demo-s2i.git' --strategy=docker --dockerfile="${S2I_MODIFIED_ISOLATED_DOCKERFILE_RHEL}" || { echo "FAILED: could not create isolated build" && exit 1; }  
|| oc new-build --name=php-secure-1 --image-stream=php:latest --strategy=docker --dockerfile=$'FROM scratch\nRUN USERID_NUMERIC=`id -u`\nUSER 0\nRUN mv ${STI_SCRIPTS_PATH}/assemble ${STI_SCRIPTS_PATH}/assemble-previous\nRUN echo $\'. ${STI_SCRIPTS_PATH}/assemble-previous\\nmv index.php index-previous.php\\nmv classification.php index.php\\n\' > ${STI_SCRIPTS_PATH}/assemble && chmod a+x ${STI_SCRIPTS_PATH}/assemble \nUSER ${USERID_NUMERIC}\n' --code=https://github.com/michaelepley/openshift-templates.git --context-dir=resources/php/classification 






The Jupyter HTML Notebook.

This launches a Tornado based HTML Notebook Server that serves up an
HTML5/Javascript Notebook client.

Subcommands
-----------

Subcommands are launched as `jupyter-notebook cmd [args]`. For information on
using subcommand 'cmd', do: `jupyter-notebook cmd -h`.

list
    List currently running notebook servers.
stop
    Stop currently running notebook server for a given port
password
    Set a password for the notebook server.

Options
-------

Arguments that take values are actually convenience aliases to full
Configurables, whose aliases are listed on the help line. For more information
on full configurables, see '--help-all'.

--debug
    set log level to logging.DEBUG (maximize logging output)
--generate-config
    generate default config file
-y
    Answer yes to any questions instead of prompting.
--no-browser
    Don't open the notebook in a browser after startup.
--pylab
    DISABLED: use %pylab or %matplotlib in the notebook to enable matplotlib.
--no-mathjax
    Disable MathJax

    MathJax is the javascript library Jupyter uses to render math/LaTeX. It is
    very large, so you may want to disable it if you have a slow internet
    connection, or for offline use of the notebook.

    When disabled, equations etc. will appear as their untransformed TeX source.
--allow-root
    Allow the notebook to be run from root user.
--script
    DEPRECATED, IGNORED
--no-script
    DEPRECATED, IGNORED
--log-level=<Enum> (Application.log_level)
    Default: 30
    Choices: (0, 10, 20, 30, 40, 50, 'DEBUG', 'INFO', 'WARN', 'ERROR', 'CRITICAL')
    Set the log level by value or name.
--config=<Unicode> (JupyterApp.config_file)
    Default: ''
    Full path of a config file.
--ip=<Unicode> (NotebookApp.ip)
    Default: 'localhost'
    The IP address the notebook server will listen on.
--port=<Int> (NotebookApp.port)
    Default: 8888
    The port the notebook server will listen on.
--port-retries=<Int> (NotebookApp.port_retries)
    Default: 50
    The number of additional ports to try if the specified port is not
    available.
--transport=<CaselessStrEnum> (KernelManager.transport)
    Default: 'tcp'
    Choices: ['tcp', 'ipc']
--keyfile=<Unicode> (NotebookApp.keyfile)
    Default: ''
    The full path to a private key file for usage with SSL/TLS.
--certfile=<Unicode> (NotebookApp.certfile)
    Default: ''
    The full path to an SSL/TLS certificate file.
--client-ca=<Unicode> (NotebookApp.client_ca)
    Default: ''
    The full path to a certificate authority certificate for SSL/TLS client
    authentication.
--notebook-dir=<Unicode> (NotebookApp.notebook_dir)
    Default: ''
    The directory to use for notebooks and kernels.
--browser=<Unicode> (NotebookApp.browser)
    Default: ''
    Specify what command to use to invoke a web browser when opening the
    notebook. If not specified, the default browser will be determined by the
    `webbrowser` standard library module, which allows setting of the BROWSER
    environment variable to override it.
--pylab=<Unicode> (NotebookApp.pylab)
    Default: 'disabled'
    DISABLED: use %pylab or %matplotlib in the notebook to enable matplotlib.
--gateway-url=<Unicode> (GatewayClient.url)
    Default: None
    The url of the Kernel or Enterprise Gateway server where kernel
    specifications are defined and kernel management takes place. If defined,
    this Notebook server acts as a proxy for all kernel management and kernel
    specification retrieval.  (JUPYTER_GATEWAY_URL env var)

To see all available configurables, use `--help-all`

Examples
--------

    jupyter notebook                       # start the notebook
    jupyter notebook --certfile=mycert.pem # use SSL/TLS certificate
    jupyter notebook password              # enter a password to protect the server

(app-root) sh-4.2$




