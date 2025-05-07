

interface Friends
{
  ID: string;
  Name: string;
  IconPath: string;
  PreView: string;
}


type frd = Map<string, Friends[]>

@Component
export struct Yours {
  @State hot_frd: Friends[] = []
  @State friends: frd = new Map<string, Friends[]>()
  @State signal: Map<string, boolean> = new Map<string, boolean>()
  @Consume('PageStack') PageStack: NavPathStack;

  aboutToAppear(): void {

  }

  build() {
    Tabs() {
      TabContent() {
        List() {
          ForEach(this.hot_frd, (item: Friends, index: number) => {
            ListItem() {
              Row() {
                Image(item.IconPath)
                Column() {
                  Text(item.Name)
                  Text(item.PreView)
                }
              }
            }
          })
        }
      }
      .tabBar("消息")

      TabContent() {
        List() {
          ForEach(Array.from(this.friends), (item: [string, Friends[]]) => {
            ListItem() {
              Button(item[0])
                .onClick(() => {
                  this.signal[item[0]] = !this.signal[item[0]]
                })
              if (this.signal[item[0]]) {
                ForEach(item[1], (elem: Friends, index: number) => {
                  ListItem() {
                    Row() {
                      Image(elem.IconPath)
                      Column() {
                        Text(elem.Name)
                      }
                    }
                  }
                })
              }
            }
          })
        }
      }
      .tabBar("联系人")
    }

  }
}