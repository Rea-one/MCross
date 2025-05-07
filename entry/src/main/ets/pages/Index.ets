import { RegANDLog } from './ralpage'
import { RegPage } from './register'
import { WaitPage } from './wait'
import {Linker} from './linker'
import { Yours } from './yours';
import { Storage } from './storage'

@Entry
@Component
struct Index
{
  @Provide('PageStack') pageStack: NavPathStack = new NavPathStack();
  @Provide('linker') link: Linker = new Linker()
  @Provide('store') store: Storage = new Storage()

  @Builder
  page_map(name: string)
  {
    if      (name == 'ralPage')     { RegANDLog() }
    else if (name == 'register')    { RegPage() }
    else if (name == 'yours')       { Yours() }
    else                            { WaitPage(); }
  }

  aboutToAppear()
  {
    this.link.init()
    this.pageStack.pushPathByName('', '');
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