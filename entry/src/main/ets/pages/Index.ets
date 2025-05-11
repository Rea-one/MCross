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
import { NetworkService, Waiter } from './manager';
import { rscPage } from './rscPage';

@Entry
@Component
struct Index
{
  @Provide('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Provide('Options') Options: distributedKVStore.Options = {
    createIfMissing: true,
    encrypt: false,
    backup: false,
    autoSync: false,
    kvStoreType: distributedKVStore.KVStoreType.DEVICE_COLLABORATION,
    securityLevel: distributedKVStore.SecurityLevel.S3
  }
  link: Linker = new Linker()
  @Provide('nets') nets: NetworkService = new NetworkService(this.link)
  @Provide('waiter') waiter: Waiter = new Waiter()

  @Builder
  page_map(name: string)
  {
    if      (name == 'ral')         { RegANDLog() }
    else if (name == 'register')    { RegPage() }
    else if (name == 'yours')       { Yours() }
    else if (name == 'chat')        { ChatPage() }
    else if (name == 'research')    { rscPage() }
    else                            { WaitPage() }
  }

  aboutToAppear()
  {
    this.link.init()
    this.pageStack.pushPathByName('', '');
    this.waiter.init(this.Options, this.nets)
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