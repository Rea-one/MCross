import { Storage } from "./storage";
import { distributedKVStore } from "@kit.ArkData";
import { Linker } from "./linker";
import { socket } from "@kit.NetworkKit";
import { systemDateTime } from "@kit.BasicServicesKit";
import { Pref } from "./preference";
import { image } from '@kit.ImageKit';
import { MaxCountType, MaxSelected } from "@kit.MediaLibraryKit";


export interface One {
  ID: string;
  Name: string;
  IconPath: string;
  Group: string
}

export interface  message {
  timestamp: string,
  message: string,
  isSender: boolean
}

export interface Frd {
  friends: Map<string, One>;
  messages: Map<string, message[]>;
}


interface Bunch {
  one: One;
  preview: string;
}

@Component
export struct Yours {
  @Provide('friend')        mess: message[] = []

  @Consume('self')          self: One
  @Consume('pageStack')     pageStack: NavPathStack;
  @Consume('store')         store: Storage

  @Consume('ones')          ones: distributedKVStore.SingleKVStore | null
  @Consume('hot')           hot: distributedKVStore.SingleKVStore | null
  @Consume('message')       message_store: distributedKVStore.SingleKVStore | null
  @Consume('image')         image_store: distributedKVStore.SingleKVStore | null

  @Consume('linker')        link: Linker
  @Consume('storeOptions')  storeOptions: distributedKVStore.Options
  @Consume('timestamp')     timestamp: string | undefined
  @Consume('preferences')   pref: Pref

  @State unfold: Map<string, [boolean, string[]]> = new Map<string, [boolean, string[]]>()
  @State friends: Frd = {
    friends: new Map<string, One>(),
    messages: new Map<string, message[]>()
  }
  @State Index: string[] = []

  aboutToAppear(): void {

    // 读取好友信息
    this.store.store?.getKVStore('ones', this.storeOptions, (err, feedback: distributedKVStore.SingleKVStore) => {
      if (err){
        console.log("数据库读取失败")
        return
      }
      this.ones = feedback
      feedback.getEntries("", (error, value) => {
        if (error) {
          console.log("数据库读取失败")
          return
        }
        value.forEach(elem => {
          let rec = elem.value.value.toString().split((" "))
          if (elem.key == "self") {
            this.self.Name = rec[0]
            this.self.IconPath = rec[1]
          } else {
            let cuf: One = {
              ID: elem.key,
              Name: rec[0],
              IconPath: rec[1],
              Group: rec[2]
            }
            this.friends.friends[cuf.ID] = cuf
          }
        })
      })
    })
    this.store.store?.getKVStore('image', this.storeOptions, (err, feedback: distributedKVStore.SingleKVStore) => {
      if (err) {
        console.log("数据读取失败")
        return
      }
      this.image_store = feedback
    })
    this.store.store?.getKVStore('hot', this.storeOptions, (err, feedback: distributedKVStore.SingleKVStore) => {
      if (err) {
        console.log("数据库读取失败")
        return
      }
      this.hot = feedback
      feedback.getEntries("", (error, value) => {
        value.forEach(elem => {
          let rec= elem.value.value.toString()
          this.Index.push(rec)
        })
      })
    })
    // 读取消息记录
    this.store.store?.getKVStore('messages', this.storeOptions, (err, feedback: distributedKVStore.SingleKVStore) => {
      if (err){
        console.log("数据库读取失败")
        return
      }
      this.message_store = feedback
      feedback.getEntries('', (error, value) => {
        if (error) {
          console.log("数据库读取失败")
          return
        }
        value.forEach(elem => {
          let rec = elem.value.value.toString().split(" ")
          for (let idx = 0; idx < rec.length; idx += 3){
            if (rec[idx + 2] == '0'){
              this.friends.messages[elem.key].push({
                timestamp: rec[idx],
                message: rec[idx + 1],
                isSender: false
              })
            } else {
              this.friends.messages[elem.key].push({
                timestamp: rec[idx],
                message: rec[idx + 1],
                isSender: true
              })
              this.update_stamp(rec[idx])
            }
          }
        })
      })
    })
    this.link.send(`sync ${this.timestamp}`, (cMess: socket.SocketMessageInfo) => {
      let translated: string = ""
      for (let order = 0; order < cMess.message.byteLength; order ++){
        translated += String.fromCharCode(cMess.message[order])
      }
      let tar = translated.split(" ")
      let cursor = 1
      switch (tar[cursor]){
        case "message":
          cursor ++
          let frd = tar[cursor]
          cursor ++
          let chatType = tar[cursor]
          cursor ++
          let mess = ""
          for(; cursor < tar.length; cursor ++){
            mess += tar[cursor]
          }
          this.friends.messages[frd].push({
            timestamp: tar[0],
            message: mess,
            isSender: chatType == "send"
          })
          break
        case "image":
          let ID = rec[cursor]

      }
      return ""
    })
  }

  build() {
    Tabs() {
      TabContent() {
        List() {
          ForEach(this.Index, (item: string, index: number) => {
            ListItem() {
              Button(){
                Row() {
                  Image(this.friends.friends[item].IconPath)
                  Column() {
                    Text(this.friends.friends[item].Name)
                  }
                }
              }
              .onClick(() => {
                this.mess = this.friends.messages[item]
                this.pageStack.pushPathByName("chat", "")
              })
            }
          })
        }
      }
      .tabBar("消息")

      TabContent() {
        List() {
          ForEach(Array.from(this.unfold), (item: [string, [boolean, string[]]]) => {
            ListItem() {
              Button(item[0])
                .onClick(() => {
                  item[1][0] = !item[1][0]
                })
            }
            if (item[1][0]) {
              ForEach(item[1][1], (elem: string, index: number) => {
                ListItem() {
                  Button(){
                    Row() {
                      Image(this.friends.friends[elem].IconPath)
                      Text(this.friends.friends[elem].Name)
                    }
                  }
                  .onClick(() => {
                    this.mess = this.friends.messages[elem]
                    this.pageStack.pushPathByName("chat", '')
                  })
                }
              })
            }
          })
        }
      }
      .tabBar("联系人")
    }
  }
  update_stamp(now: string) {
    if (typeof(this.timestamp) === "undefined" || this.timestamp < now){
      this.timestamp = now
    }
  }
}