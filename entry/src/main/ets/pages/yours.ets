import { Storage } from "./storage";
import { distributedKVStore } from "@kit.ArkData";
import { Linker } from "./linker";
import { socket } from "@kit.NetworkKit";
import { fileIo } from "@kit.CoreFileKit"
import { Pref } from "./preference";
import { image } from '@kit.ImageKit';
import { MaxCountType, MaxSelected } from "@kit.MediaLibraryKit";
import { common } from '@kit.AbilityKit';
import { One, Waiter } from "./manager";


@Component
export struct Yours {
  @Consume('pageStack') pageStack: NavPathStack;
  @Consume('waiter') waiter: Waiter

  @Provide('chatTar') chatTar: string = ""

  @State unfold: Map<string, [boolean]> = new Map<string, [boolean]>()

  private context = this.getUIContext().getHostContext() as common.UIAbilityContext

  aboutToAppear(): void {
    for (let elem of this.waiter.the_frd) {
      this.unfold[elem[0]] = false
    }
  }

  build() {
    Tabs() {
      TabContent() {
        List() {
          ForEach(this.waiter.the_hot, (item: string, index: number) => {
            ListItem() {
              Button(){
                Row() {
                  Image(this.waiter.getImg(this.waiter.getSgn(item).IconID))
                  Column() {
                    Text(this.waiter.getSgn(item).Name)
                  }
                }
              }
              .onClick(() => {
                this.chatTar = this.waiter.getSgn(item).Name
                this.pageStack.pushPathByName("chat", "")
              })
            }
          })
        }
      }
      .tabBar("消息")

      TabContent() {
        List() {
          ForEach(Array.from(this.unfold), (item: [string, boolean]) => {
            ListItem() {
              Button(item[0])
                .onClick(() => {
                  item[1] = !item[1]
                })
            }
            if (item[1]) {
              ForEach(this.waiter.the_frd[item[0]], (target: string, index: number) => {
                ListItem() {
                  Button(){
                    Row() {
                      Image(this.waiter.getImg(this.waiter.getSgn(item[target]).IconID))
                      Text(this.waiter.getSgn(item[0]).Name)
                    }
                  }
                  .onClick(() => {
                    this.chatTar = item[0]
                    this.pageStack.pushPathByName("chat", '')
                  })
                }
              })
            }
          })
        }
      }
      .tabBar("联系人")
      TabContent(){
        Column(){
          Button("添加好友")
          Button("设置")
        }
      }
      .tabBar("更多")
    }
  }
}