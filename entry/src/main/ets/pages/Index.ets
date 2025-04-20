import { RegANDLog } from './ralpage'
import { RegPage } from './register'
import { WaitPage } from './wait'

@Entry
@Component
struct Index
{
  @Provide('PageStack') pageStack: NavPathStack = new NavPathStack();

  @Builder
  page_map(name: string)
  {
    if (name == 'ralPage')
    {
      RegANDLog();
    }
    else if (name == 'register')
    {
      RegPage()
    }
    else
    {
      WaitPage();
    }
  }

  aboutToAppear()
  {
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