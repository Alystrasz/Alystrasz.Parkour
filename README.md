# NSModTemplate
A template repository for Northstar mods with a ~~mostly~~ pre-configured github action for publishing to Thunderstore

## Usage
<ol>
<li> Click the <code>Use this template</code> button on the top right of the repo's landing page (<a href="https://github.com/GreenTF/NSModTemplate">here</a>)</li>
<li> Give the new repo a name and make sure it's set to <code>public</code></li>
<li> <details><summary> In the <code>settings</code> tab, under <code>actions</code> -> <code>general</code>, set <code>Actions permissions</code> to <code>Allow all actions and reusable workflows</code></summary>
<img src="https://user-images.githubusercontent.com/4367791/180306016-04bfc321-b60f-4ed0-ac0c-5a6065036e2c.png" />
</details></li>
<li> <details><summary> Also in <code>settings</code>, under <code>secrets</code> ->  <code>actions</code>, add your Thunderstore token as a secret named <code>TS_KEY</code> (Steps for getting a token can be found <a href="https://github.com/GreenTF/upload-thunderstore-package/wiki">here</a>)</summary>
  <img src="https://user-images.githubusercontent.com/4367791/180306285-60dd51ec-0448-44af-aa92-682599c6c0f4.png" />
  <img src="https://user-images.githubusercontent.com/4367791/180306391-a217f309-e875-4e74-8270-8155c60dbcdc.png" />
</details>
</li>
  <li> <details><summary>Edit <code>.github/workflows/publish.yml</code> ~line 43 to add a description for your mod </summary>
    <img src="https://user-images.githubusercontent.com/4367791/180337843-5213db45-850b-4759-98c5-9ad47cbab7ba.png" />
    </details>
  </li>

<li> Update this README and <code>icon.png</code> as they will be used by Thunderstore as well </li>
<li> Write your mod! (HINT: Find the docs <a href="https://r2northstar.readthedocs.io/en/latest/guides/gettingstarted.html">here</a>) </li>
</ol>


