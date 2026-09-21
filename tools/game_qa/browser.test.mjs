// Serve build/web beneath /umt3033_flutter/ before running npm run browser.
import { chromium } from 'playwright';
import assert from 'node:assert/strict';
import { mkdir } from 'node:fs/promises';
const base=process.env.GAME_TEST_URL || 'http://localhost:8765/umt3033_flutter/';
const browser=await chromium.launch({channel:'chrome',headless:true});
const ctx=await browser.newContext({viewport:{width:1440,height:900}});
const errors=[]; const artifacts='../../build/game-qa';await mkdir(artifacts,{recursive:true});
async function semantics(page) {
 for(let i=0;i<80;i++) {
   if(await page.locator('flt-semantics-placeholder').count()) await page.locator('flt-semantics-placeholder').evaluate(el=>el.click());
   if((await page.locator('body').innerText()).length>30) {await page.waitForTimeout(300); return;}
   await page.waitForTimeout(200);
 }
 throw new Error('Flutter semantics did not initialize');
}
async function open(page,path){page.on('pageerror',e=>errors.push(e.message));await page.goto(base+'#'+path);await semantics(page);console.log('Opened',path);}
async function text(page) {return page.locator('body').innerText();}
async function waitText(page,expected){await page.getByText(expected,{exact:false}).first().waitFor({timeout:12000});}
try {
 const host=await ctx.newPage(); await open(host,'/game');
 await host.screenshot({path:artifacts+'/menu.png'});
 await host.getByRole('button',{name:'Let’s go →'}).nth(2).click();await host.getByRole('button',{name:'Create class game →'}).click();console.log('Created room');
 await waitText(host,'SCAN TO JOIN');
 const code=await host.evaluate(()=>sessionStorage.getItem('adventure_host_room'));
 assert.match(code,/^[A-Z2-9]{6}$/);
 assert.match(await text(host),/Room join QR code/);
 const players=[];
 for (const name of ['Aisyah','Hakim']) {
   const p=await ctx.newPage();await p.setViewportSize({width:390,height:844});await open(p,'/game/join?room='+code);
   // Flutter paints text values on canvas; successful join without entering
   // a code verifies the QR query parameter, not the empty DOM mirror input.
   await p.getByRole('textbox').nth(1).fill(name);
   await p.getByRole('button',{name:'Join adventure →'}).click();await waitText(p,'You’re in, '+name);
   players.push(p);
 }
 await waitText(host,'Players joined: 2 / 50');await host.screenshot({path:artifacts+'/lobby.png'});
 await host.reload();await semantics(host);await waitText(host,'Players joined: 2 / 50');
 await host.getByRole('button',{name:'START RACE'}).click();await players[0].waitForTimeout(4500);
 await waitText(players[0],'Gate 0/9');await host.screenshot({path:artifacts+'/race.png'});
 await players[0].screenshot({path:artifacts+'/mobile-play.png'});
 // Hold actual touch control, release, then confirm the host receives progress.
 const right=players[0].getByRole('button',{name:'Right',exact:true});
 const bounds=await right.boundingBox();await players[0].mouse.move(bounds.x+bounds.width/2,bounds.y+bounds.height/2);
 await players[0].mouse.down();await players[0].waitForTimeout(900);await players[0].mouse.up();await host.waitForTimeout(1600);
 const before=await host.evaluate(code=>(()=>{const v=JSON.parse(localStorage.getItem('flutter.adventure_demo_room_'+code));return typeof v==='string'?JSON.parse(v):v;})(),code);
 assert.ok(Object.values(before.players).find(p=>p.nickname==='Aisyah').run.progress>.01);
 await host.getByRole('button',{name:'Pause',exact:true}).click();await waitText(players[0],'Class race paused');
 await host.getByRole('button',{name:'Resume',exact:true}).click();await players[0].waitForTimeout(600);
 await players[0].reload();await semantics(players[0]);await waitText(players[0],'Gate 0/9');
 await host.getByRole('button',{name:'End & results'}).click();await host.getByRole('button',{name:'Next world →'}).waitFor();
 await host.screenshot({path:artifacts+'/results.png'});await waitText(players[0],'Stay here for the next world.');
 await host.getByRole('button',{name:'Next world →'}).click();await waitText(host,'WORLD 2');await waitText(players[0],'Waiting for your lecturer');
 // The existing app still loads on the original root route.
 const course=await ctx.newPage();await open(course,'/');await waitText(course,'Arabic Muamalat Adventure');
 // Solo hash route is directly reloadable and persists during play.
 const solo=await ctx.newPage();await solo.setViewportSize({width:390,height:844});await open(solo,'/game/play?level=1&avatar=1');
 await waitText(solo,'Gate 0/9');await solo.waitForTimeout(1500);await solo.reload();await semantics(solo);await waitText(solo,'Gate 0/9');
 assert.equal(errors.length,0,errors.join('\n'));
 console.log('PASS: release browser root, menu, QR, 2 real player tabs, host/player refresh, touch movement, progress, pause/resume, results, next level and solo refresh.');
} catch(error) { for(const [i,page] of ctx.pages().entries()) {console.log('Failure page',i,page.url(),await text(page));await page.screenshot({path:artifacts+'/failure-'+i+'.png'});}throw error;} finally {await browser.close();}
