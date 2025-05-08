import { preferences } from '@kit.ArkData';

import { UIAbility } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { window } from '@kit.ArkUI';


export class Pref extends UIAbility {
  dp: preferences.Preferences | null = null;
  onCreate() {
    let options: preferences.Options = { name: 'now' };
    this.dp = preferences.getPreferencesSync(this.context, options);
  }
}