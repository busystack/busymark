from pathlib import Path
import hashlib,json,struct
r=Path('/home/ubuntu/busystack-native-git-verification-20261031');o=r/'log-toolbar-refinement-20261102';probe=o/'cache-probe';probe.mkdir()
s=(r/'log_toolbar_fixture.py').read_text().replace("r/'log-toolbar-refinement-20261102'", "r/'log-toolbar-refinement-20261102/cache-probe'")
s=s.replace("(out/'fixture-before.json').write_text", "(out/'index-before-status.bin').write_bytes((f/'.git/index').read_bytes())\n(out/'fixture-before.json').write_text")
exec(compile(s,'task-fixture-cache-probe','exec'),{})
a=(probe/'index-before-status.bin').read_bytes();b=(probe/'fixture/.git/index').read_bytes()
def entries(raw):
 assert raw[:4]==b'DIRC' and struct.unpack('>I',raw[4:8])[0]==2
 count=struct.unpack('>I',raw[8:12])[0];i=12;result={}
 for n in range(count):
  start=i;data=list(struct.unpack('>10I',raw[i:i+40]));oid=raw[i+40:i+60].hex();flags=struct.unpack('>H',raw[i+60:i+62])[0];i=raw.index(b'\0',i+62);name=raw[start+62:i].decode();i=start+((i-start+1+7)//8)*8
  result[name]=dict(stat=data,oid=oid,flags=flags)
 return result,raw[i:-20].hex()
ae,ax=entries(a);be,bx=entries(b)
receipt=dict(noApplicationWasLaunched=True,before=hashlib.sha256(a).hexdigest(),after=hashlib.sha256(b).hexdigest(),indexChanged=a!=b,entryChanges={k:[ae.get(k),be.get(k)] for k in ae.keys()|be.keys() if ae.get(k)!=be.get(k)},extensionChanged=ax!=bx)
(o/'index-cache-probe.json').write_text(json.dumps(receipt,indent=2));print(json.dumps(receipt))
