# Specific tasks for the UDF lab only
(lab link: https://udf.f5.com/b/35de67cc-3c12-4da7-9b63-d5ff2879712f#documentation)

We will do most of the tasks under cloud-user (from ocp-provisioner vm as jumphost)
```
su - cloud-user
```
Switch the current context
```
oc config use-context default/api-ocp-f5-udf-com:6443/recovery
```

Renew certs. After this step, you will see all nodes are in ready state:
```
while date ; do
  oc get nodes
  oc get csr --no-headers | grep Pending | awk '{print $1}' | xargs --no-run-if-empty oc  adm certificate approve
  sleep 5
done
```

We will use the user f5admin/f5admin to manage OCP. In the UDF lab, it's created but can be expired

If not created, let do this first:
```
htpasswd -c -B -b users.htpasswd f5admin f5admin
oc create secret generic htpass-secret --from-file=htpasswd=users.htpasswd -n openshift-config
```

Create a file myHtpasswdProvider.yaml 
```
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  tokenConfig:
    accessTokenMaxAgeSeconds: 2592000
  identityProviders:
  - name: myHtpasswdProvider
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
```
Run:
```
oc apply -f myHtpasswdProvider.yaml
```

Login to OCP using f5admin user
```
oc login -u f5admin -p f5admin --certificate-authority=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
```

# Basic tests to confirm we have a working OCP

Create a new sample app from the template (get a list of sample template by `oc new-app -L`)
```
oc new-app --template=nginx-example -l name=testapp
```
Check the status by `oc status`

If you are on an empty namespace/project, run `oc get all --show-labels` to see all created resources

Result is similar to the below:
```
NAME                        READY   STATUS    RESTARTS   AGE   LABELS
pod/nginx-example-1-build   1/1     Running   0          10s   openshift.io/build.name=nginx-example-1

NAME                    TYPE           CLUSTER-IP     EXTERNAL-IP                            PORT(S)    AGE    LABELS
service/kubernetes      ClusterIP      192.168.1.1    <none>                                 443/TCP    727d   component=apiserver,provider=kubernetes
service/nginx-example   ClusterIP      192.168.1.23   <none>                                 8080/TCP   10s    app=nginx-example,name=testapp,template=nginx-example
service/openshift       ExternalName   <none>         kubernetes.default.svc.cluster.local   <none>     727d   <none>

NAME                            READY   UP-TO-DATE   AVAILABLE   AGE   LABELS
deployment.apps/nginx-example   0/1     0            0           10s   app=nginx-example,name=testapp,template=nginx-example

NAME                                       DESIRED   CURRENT   READY   AGE   LABELS
replicaset.apps/nginx-example-6c4b966948   1         0         0       10s   app=nginx-example,name=nginx-example,pod-template-hash=6c4b966948

NAME                                           TYPE     FROM   LATEST   LABELS
buildconfig.build.openshift.io/nginx-example   Source   Git    1        app=nginx-example,name=testapp,template=nginx-example

NAME                                       TYPE     FROM          STATUS    STARTED         DURATION   LABELS
build.build.openshift.io/nginx-example-1   Source   Git@afc41b7   Running   9 seconds ago              app=nginx-example,buildconfig=nginx-example,name=testapp,openshift.io/build-config.name=nginx-example,openshift.io/build.start-policy=Serial,template=nginx-example

NAME                                           IMAGE REPOSITORY                                                                   TAGS   UPDATED   LABELS
imagestream.image.openshift.io/nginx-example   default-route-openshift-image-registry.apps.ocp.f5-udf.com/default/nginx-example                    app=nginx-example,name=testapp,template=nginx-example

NAME                                     HOST/PORT                                   PATH   SERVICES        PORT    TERMINATION   WILDCARD   LABELS
route.route.openshift.io/nginx-example   nginx-example-default.apps.ocp.f5-udf.com          nginx-example   <all>                 None       app=nginx-example,name=testapp,template=nginx-example
```
get the list of pod and their IPs:
```
oc get pod -o wide
```
Result is similar to the below (10.244.3.23):
```
NAME                             READY   STATUS      RESTARTS   AGE     IP            NODE                      NOMINATED NODE   READINESS GATES
nginx-example-1-build            0/1     Completed   0          5m25s   10.244.3.18   worker-1.ocp.f5-udf.com   <none>           <none>
nginx-example-6468c9784f-k5gkv   1/1     Running     0          5m2s    10.244.3.23   worker-1.ocp.f5-udf.com   <none>           <none>
```

get the list of nodes' IP:
```
oc get nodes -o wide
```

Result is similar to the below:
```
NAME                      STATUS   ROLES                         AGE    VERSION           INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                                                KERNEL-VERSION                 CONTAINER-RUNTIME
master-1.ocp.f5-udf.com   Ready    control-plane,master,worker   727d   v1.29.8+f10c92d   10.1.10.6     <none>        Red Hat Enterprise Linux CoreOS 416.94.202409191851-0   5.14.0-427.37.1.el9_4.x86_64   cri-o://1.29.8-6.rhaos4.16.gitea41abd.el9
master-2.ocp.f5-udf.com   Ready    control-plane,master,worker   727d   v1.29.8+f10c92d   10.1.10.7     <none>        Red Hat Enterprise Linux CoreOS 416.94.202409191851-0   5.14.0-427.37.1.el9_4.x86_64   cri-o://1.29.8-6.rhaos4.16.gitea41abd.el9
master-3.ocp.f5-udf.com   Ready    control-plane,master,worker   727d   v1.29.8+f10c92d   10.1.10.8     <none>        Red Hat Enterprise Linux CoreOS 416.94.202409191851-0   5.14.0-427.37.1.el9_4.x86_64   cri-o://1.29.8-6.rhaos4.16.gitea41abd.el9
worker-1.ocp.f5-udf.com   Ready    worker                        727d   v1.29.8+f10c92d   10.1.10.9     <none>        Red Hat Enterprise Linux CoreOS 416.94.202409191851-0   5.14.0-427.37.1.el9_4.x86_64   cri-o://1.29.8-6.rhaos4.16.gitea41abd.el9
worker-2.ocp.f5-udf.com   Ready    worker                        727d   v1.29.8+f10c92d   10.1.10.10    <none>        Red Hat Enterprise Linux CoreOS 416.94.202409191851-0   5.14.0-427.37.1.el9_4.x86_64   cri-o://1.29.8-6.rhaos4.16.gitea41abd.el9
```

There are 2 tests you may want to do:

Connecting to the app from another container (with curl) in the same namespace/project
```
oc run mycurl --image=radial/busyboxplus:curl -i --tty --rm

when you see the prompt, let curl to the IP address/port of the pod:

curl -I http://10.244.3.23:8080

You should see:
[ root@mycurl:/ ]$ curl -I http://10.244.3.23:8080
HTTP/1.1 200 OK
Server: nginx/1.20.1
Date: Fri, 13 Jun 2025 03:25:57 GMT
Content-Type: text/html
Content-Length: 37451
Last-Modified: Fri, 13 Jun 2025 02:55:26 GMT
Connection: keep-alive
ETag: "684b931e-924b"
Accept-Ranges: bytes

```
If it works, you can proceed to the 2nd test, test from outside of the cluster. 
- Just connect to any node (eg: 10.1.10.9), 
- Host header should be matched with the Route (eg: nginx-example-default.apps.ocp.f5-udf.com)
```
curl -I http://nginx-example-default.apps.ocp.f5-udf.com --resolve nginx-example-default.apps.ocp.f5-udf.com:80:10.1.10.9
```
If both of the tests work, you can continue

You can delete the test app by:
```
oc delete all -l app=nginx-example
```

# Deploy F5 CIS container using ClusterIP Mode
Create a secret, serviceaccount, clusterrolebinding
```
oc create secret generic bigip-login -n kube-system --from-literal=username=admin --from-literal=password=F5site02@
oc create serviceaccount k8s-bigip-ctlr -n kube-system
oc create clusterrolebinding k8s-bigip-ctlr-clusteradmin --clusterrole=cluster-admin --serviceaccount=kube-system:k8s-bigip-ctlr
```

Create a deployment file (`cluster-deployment.yaml`):
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8s-bigip-ctlr-deployment
  namespace: kube-system
spec:
  # DO NOT INCREASE REPLICA COUNT
  replicas: 1
  selector:
    matchLabels:
      app: k8s-bigip-ctlr-deployment
  template:
    metadata:
      labels:
        app: k8s-bigip-ctlr-deployment
    spec:
      # Name of the Service Account bound to a Cluster Role with the required
      # permissions
      containers:
        - name: cntr-ingress-svcs
          image: registry.connect.redhat.com/f5networks/cntr-ingress-svcs:latest
          env:
            - name: BIGIP_USERNAME
              valueFrom:
                secretKeyRef:
                  # Replace with the name of the Secret containing your login
                  # credentials
                  name: bigip-login
                  key: username
            - name: BIGIP_PASSWORD
              valueFrom:
                secretKeyRef:
                  # Replace with the name of the Secret containing your login
                  # credentials
                  name: bigip-login
                  key: password
          command: ["/app/bin/k8s-bigip-ctlr"]
          args: [
            # See the k8s-bigip-ctlr documentation for information about
            # all config options
            # https://clouddocs.f5.com/containers/latest/
              "--bigip-username=$(BIGIP_USERNAME)",
              "--bigip-password=$(BIGIP_PASSWORD)",
              "--bigip-url=10.1.1.5",
              "--bigip-partition=ocp",
              "--namespace=default",
              "--pool-member-type=cluster",
              "--enable-ipv6=false",
              #"--openshift-sdn-name=/Common/okd-tunnel",
              "--log-level=DEBUG",
              "--insecure=true",
              "--manage-routes=true",
              "--static-routing-mode=true",
              "--extended-spec-configmap=kube-system/extended-cm",
              "--route-vserver-addr=10.1.10.11",
              "--orchestration-cni=ovn-k8s",
              "--route-http-vserver=ocp_http_vs",
              "--route-https-vserver=ocp_https_vs",        
              #"--override-as3-declaration=default/cafe-override",
              "--as3-validation=true",
              "--log-as3-response=true",
              "--disable-teems=true",
          ]
      serviceAccountName: k8s-bigip-ctlr
```

Create the deployment:
```
oc create -f cluster-deployment.yaml
```
Check if the pod is running and check the log:
```
oc get pod -n kube-system
oc logs -n kube-system k8s-bigip-ctlr-deployment-9d76d4987-n6tdk
```

# Deploy a sample 'hello world' application

Create file deployment-hello-world.yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: f5-hello-world-web
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: f5-hello-world-web
  template:
    metadata:
      labels:
        app: f5-hello-world-web
    spec:
      containers:
      - env:
        - name: service_name
          value: f5-hello-world-web
        image: f5devcentral/f5-hello-world:develop
        imagePullPolicy: IfNotPresent
        name: f5-hello-world-web
        ports:
        - containerPort: 8080
          protocol: TCP
```
Create file clusterip-service-hello-world.yaml
```
apiVersion: v1
kind: Service
metadata:
  name: f5-hello-world-web
  namespace: default
  labels:
    app: f5-hello-world-web
    cis.f5.com/as3-tenant: AS3
    cis.f5.com/as3-app: A1
    cis.f5.com/as3-pool: web_pool
spec:
  ports:
  - name: f5-hello-world-web
    port: 8080
    protocol: TCP
    targetPort: 8080
  type: ClusterIP
  selector:
    app: f5-hello-world-web
```
Create file route-hello-world.yaml
```
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  labels:
    f5type: hello-world
    name: f5-hello-world-web
  name: f5-hello-world-web
  namespace: default
  annotations:
    virtual-server.f5.com/balance: round-robin
    virtual-server.f5.com/health: |
      [
        {
          "path": "mysite.f5demo.com/",
          "send": "HTTP GET /",
          "interval": 5,
          "timeout": 10
        }
      ]
spec:
  host: mysite.f5demo.com
  path: "/"
  port:
    targetPort: 8080
  to:
    kind: Service
    name: f5-hello-world-web
```

Create a test deployment, service and route for it
```
oc create -f deployment-hello-world.yaml
oc create -f clusterip-service-hello-world.yaml
oc create -f route-hello-world.yaml
```
Check the status of the resources:
```
oc get all
```
You should see some thing like this:
```
NAME                                      READY   STATUS    RESTARTS   AGE
pod/f5-hello-world-web-6669b59749-5rphb   1/1     Running   0          151m
pod/f5-hello-world-web-6669b59749-vn8zd   1/1     Running   0          151m

NAME                         TYPE           CLUSTER-IP      EXTERNAL-IP                            PORT(S)    AGE
service/f5-hello-world-web   ClusterIP      192.168.1.163   <none>                                 8080/TCP   151m
service/kubernetes           ClusterIP      192.168.1.1     <none>                                 443/TCP    727d
service/openshift            ExternalName   <none>          kubernetes.default.svc.cluster.local   <none>     727d

NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/f5-hello-world-web   2/2     2            2           151m

NAME                                            DESIRED   CURRENT   READY   AGE
replicaset.apps/f5-hello-world-web-6669b59749   2         2         2       151m

NAME                                          HOST/PORT                      PATH   SERVICES             PORT   TERMINATION   WILDCARD
route.route.openshift.io/f5-hello-world-web   mysite.f5demo.com ... 1 more   /      f5-hello-world-web   8080                 None
```

Make a test:
```
curl -I  -H 'Host: mysite.f5demo.com' http://10.1.10.11
```

Result should be similar to this:
```
HTTP/1.1 200 OK
Date: Fri, 13 Jun 2025 07:15:09 GMT
Server: Apache/2.4.25 (Debian)
Vary: Accept-Encoding
Set-Cookie: Cookie=Monster; Path=/; HttpOnly
Content-Type: text/html; charset=UTF-8
Set-Cookie: BIGipServer~ocp~Shared~openshift_default_f5_hello_world_web=486863882.36895.0000; path=/; Httponly
```

Take a look at BIG-IP Configuration Utility:
- Partition ocp
- Virtual Server
- Traffic Policy
- Pool and pool members
- Static routes

# Deploy Hello-World Using ConfigMap w/ AS3

Create file deployment-hello-world.yaml (as same as the above)
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: f5-hello-world-web
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: f5-hello-world-web
  template:
    metadata:
      labels:
        app: f5-hello-world-web
    spec:
      containers:
      - env:
        - name: service_name
          value: f5-hello-world-web
        image: f5devcentral/f5-hello-world:develop
        imagePullPolicy: IfNotPresent
        name: f5-hello-world-web
        ports:
        - containerPort: 8080
          protocol: TCP
```

Create file clusterip-service-hello-world.yaml (as same as above)
```
apiVersion: v1
kind: Service
metadata:
  name: f5-hello-world-web
  namespace: default
  labels:
    app: f5-hello-world-web
    cis.f5.com/as3-tenant: AS3
    cis.f5.com/as3-app: A1
    cis.f5.com/as3-pool: web_pool
spec:
  ports:
  - name: f5-hello-world-web
    port: 8080
    protocol: TCP
    targetPort: 8080
  type: ClusterIP
  selector:
    app: f5-hello-world-web
```

Create file configmap-hello-world.yaml
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: f5-as3-declaration
  namespace: default
  labels:
    f5type: virtual-server
    as3: "true"
data:
  template: |
    {
        "class": "AS3",
        "declaration": {
            "class": "ADC",
            "schemaVersion": "3.10.0",
            "label": "http",
            "remark": "A1 example",
            "AS3": {
                "class": "Tenant",
                "A1": {
                    "class": "Application",
                    "template": "http",
                    "serviceMain": {
                        "class": "Service_HTTP",
                        "virtualAddresses": [
                            "10.1.10.11"
                        ],
                        "pool": "web_pool",
                        "virtualPort": 80
                    },
                    "web_pool": {
                        "class": "Pool",
                        "monitors": [
                            "http"
                        ],
                        "members": [
                            {
                                "servicePort": 8080,
                                "serverAddresses": []
                            }
                        ]
                    }
                }
            }
        }
    }
```
Create the resources:
```
oc create -f deployment-hello-world.yaml
oc create -f clusterip-service-hello-world.yaml
oc create -f configmap-hello-world.yaml
```
Test:
```
curl -I http://10.1.10.11
```
Question: why don't you have to specify the Host header and it still works?

Let do a scale up:
```
oc scale --replicas=10 deployment/f5-hello-world-web
```
Take a look at BIG-IP GUI (AS3 partition): Local traffic --> Pool --> web_pool (members)
