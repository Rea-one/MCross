import { distributedKVStore } from '@kit.ArkData';
import { Content } from '@ohos.arkui.node';


export class storage{
  store: distributedKVStore.KVManager | undefined = undefined
  config: distributedKVStore.KVManagerConfig | undefined = undefined

  init(){
    this.config = {
      bundleName: 'cn.edu.hit'
    }
    this.store = distributedKVStore.createKVManager(this.config)
  }
}