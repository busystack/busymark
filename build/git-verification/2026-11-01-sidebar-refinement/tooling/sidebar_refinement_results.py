from pathlib import Path
import json
root=Path('/home/ubuntu/busystack-native-git-verification-20261031/sidebar-refinement-20261101')
results={}
for path in sorted(root.glob('*.log')):
    names={}; completed=[]; done=None
    for line in path.read_text(errors='replace').splitlines():
        try: event=json.loads(line)
        except ValueError: continue
        if not isinstance(event,dict): continue
        if event.get('type')=='testStart': names[event['test']['id']]=event['test']['name']
        if event.get('type')=='testDone':
            if not event.get('hidden',False): completed.append(dict(name=names.get(event['testID']),result=event.get('result'),skipped=event.get('skipped')))
        if event.get('type')=='done': done=event
    if done is not None:
        results[path.name]=dict(done=done,completed=len(completed),failed=[r for r in completed if r['result']!='success' and not r['skipped']],tests=completed)
(root/'test-results.json').write_text(json.dumps(results,indent=2))
print(json.dumps({name:dict(completed=r['completed'],failed=len(r['failed']),done=r['done']) for name,r in results.items()},indent=2))
