# Kubernetes

Deployment into Kubernetes is simple using a [Generic Helm Chart for Deploying Web Apps](https://github.com/AbhishekKumar1602/FlaskDemoWebApplication)

Make sure you have [Helm Installed First](https://helm.sh/docs/intro/install/)

First add the Helm repo
```bash
helm repo add benc-uk https://benc-uk.github.io/helm-charts
```

Make a copy of `app.sample.yaml` to `myapp.yaml` and modify the values to suit your environment. If you're in a real hurry you can use the file as is and make no changes.
```bash
helm install demo benc-uk/webapp --values myapp.yaml
```
