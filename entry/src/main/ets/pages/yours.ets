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

  @State addFriend: boolean = false

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
          Row(){
            Text("昵称")
            Text(this.waiter.self.Name)
          }
          Row(){
            Text("账号")
            Text(this.waiter.self.ID)
          }
          Row() {
            Button()
            List() {
              if (this.addFriend) {

                ForEach(this.waiter.the_frq, (val: string) => {
                  ListItem() {
                    Row() {
                      Image(this.waiter.the_img[this.waiter.the_sgn[val].IconID])
                      Text(this.waiter.the_sgn[val].Name)
                      Button("同意")
                        .onClick(() => {

                        })
                      Button("拒绝")
                        .onClick(() => {

                        })
                    }
                  }
                })
              }
            }
          }
          Row(){
            Button("修改密码")
              .onClick(() => {
                this.pageStack.pushPathByName("reset password","")
              })
          }
          Row(){
            Button("修改昵称")
              .onClick(() => {
                this.pageStack.pushPathByName("reset Name", "")
              })
          }
          Row(){
            Button("修改头像")
              .onClick(() => {

              })
          }
        }
      }
      .tabBar("更多")
    }
  }
}