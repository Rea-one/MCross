import { distributedKVStore } from '@kit.ArkData';
import { Content } from '@ohos.arkui.node';
import { window } from '@kit.ArkUI';
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';


export class Storage extends UIAbility{
  store: distributedKVStore.KVManager | null = null

  onCreate(): void {
    let context = this.context;
    const config: distributedKVStore.KVManagerConfig = {
      context: context,
      bundleName: "cn.edu.hit"
    }
    this.store = distributedKVStore.createKVManager(config)
  }
}