
#!/usr/bin/env bash

kubectl get pods -n apps -l app=test-app --field-selector=status.phase=Running -o=jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | while read line
do
    echo "kubectl logs pod/$line -n apps -c test-app -f"
done
