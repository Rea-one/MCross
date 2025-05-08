import { RegANDLog } from './ralpage'
import { RegPage } from './register'
import { WaitPage } from './wait'
import {Linker} from './linker'
import { Yours } from './yours';
import { Storage } from './storage'
import { ChatPage } from './chat';
import { distributedKVStore } from '@kit.ArkData';
import { preferences } from '@kit.ArkData';
import { Pref } from './preference';

@Entry
@Component
struct Index
{
  @Provide('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Provide('linker')    link: Linker = new Linker()
  @Provide('store')     store: Storage = new Storage()
  @Provide('ones')      ones: distributedKVStore.SingleKVStore | null = null
  @Provide('hot')       hot: distributedKVStore.SingleKVStore | null = null
  @Provide('message')   message_store: distributedKVStore.SingleKVStore | null = null
  @Provide('image')     image_store: distributedKVStore.SingleKVStore | null = null
  @Provide('timestamp') timestamp: string | undefined= ""
  @Provide('storeOptions') storeOptions: distributedKVStore.Options = {
    createIfMissing: true,
    encrypt: false,
    backup: false,
    autoSync: false,
    kvStoreType: distributedKVStore.KVStoreType.DEVICE_COLLABORATION,
    securityLevel: distributedKVStore.SecurityLevel.S3
  }
  @Provide('preferences') pref: Pref = new Pref()

  @Builder
  page_map(name: string)
  {
    if      (name == 'ralPage')     { RegANDLog() }
    else if (name == 'register')    { RegPage() }
    else if (name == 'yours')       { Yours() }
    else if (name == 'chat')        { ChatPage() }
    else                            { WaitPage() }
  }

  aboutToAppear()
  {
    this.link.init()
    this.pageStack.pushPathByName('', '');
    this.store.store?.getKVStore('message', this.storeOptions, (error, feedback: distributedKVStore.SingleKVStore) => {

    })
    this.timestamp = this.pref.dp?.getSync("now", "string").toString()
  }

  build()
  {
    Navigation(this.pageStack)
    {
      Column()
      {
        Text('这是导航页')
          .width('100%')
          .fontColor(Color.Black)
        Button('test')
          .onClick(() =>
          {
            this.link.connect()
            this.pageStack.pushPathByName('ralPage', '')
          })
      }

    }
    .title('导航')
    .navDestination(this.page_map)
    .width('100%')
    .height('100%');

  }
}