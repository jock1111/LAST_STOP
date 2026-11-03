import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
const baseline='bbc0c34fc81ac41d4a2141d93e169bd394ab1efe';
const previous='fddf7d476fb91978ff43e13a7bae15c2e562a16d';
function inventory(xml){
  const classes={};
  for(const match of xml.matchAll(/<Item class="([^"]+)"/g)) classes[match[1]]=(classes[match[1]]||0)+1;
  return {bytes:Buffer.byteLength(xml),classes};
}
const report={baseline,previous,branch:execFileSync('git',['branch','--show-current'],{encoding:'utf8'}).trim(),commitsBeforeRecovery:execFileSync('git',['log','--format=%H %s',`${baseline}..${previous}`],{encoding:'utf8'}).trim().split('\n'),baselinePlace:inventory(execFileSync('git',['show',`${baseline}:LAST_STOP.rbxlx`],{encoding:'utf8'})),previousCanonicalPlace:inventory(execFileSync('git',['show',`${previous}:LAST_STOP.rbxlx`],{encoding:'utf8'})),recoveryPlace:inventory(fs.readFileSync('LAST_STOP.rbxlx','utf8'))};
fs.mkdirSync('qa',{recursive:true});fs.writeFileSync('qa/source-audit.json',JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));
