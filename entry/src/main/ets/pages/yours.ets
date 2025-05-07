import { Storage } from "./storage";
import { distributedKVStore } from "@kit.ArkData";


interface Friends {
  ID: string;
  Name: string;
  IconPath: string;
  PreView: string;
  Group: string
}

export interface Self{
  ID: string;
  IconPath: string;
}


interface  frd {
  flips: Map<string, Friends[]>
}

@Component
export struct Yours {
  @Consume('self') self: Self
  @State hot_frd: Friends[] = []
  @State friends: frd = {
    flips: new Map<string, Friends[]>()
  }
  @State signal: Map<string, boolean> = new Map<string, boolean>()
  @Consume('PageStack') PageStack: NavPathStack;
  @Consume('store') store: Storage

  self_store: distributedKVStore.SingleKVStore | null = null
  friend_store: distributedKVStore.SingleKVStore | null = null
  message_store: distributedKVStore.SingleKVStore | null = null

  aboutToAppear(): void {
    const options: distributedKVStore.Options = {
      createIfMissing: true,
      encrypt: false,
      backup: false,
      autoSync: false,
      kvStoreType: distributedKVStore.KVStoreType.DEVICE_COLLABORATION,
      securityLevel: distributedKVStore.SecurityLevel.S3
    }
    this.store.store?.getKVStore('self', options, (err, feedback: distributedKVStore.SingleKVStore) => {
      if (err){
        console.log("数据库读取失败")
        return
      }
      this.self_store = feedback
      this.self_store.get(this.self.ID, (error, value: string | undefined) => {
        if (error){
          console.log("头像加载失败")
          return
        }
        if (typeof value === "string") {
          this.self.IconPath = value
        }
      })
    })
    this.store.store?.getKVStore('friend', options, (err, feedback: distributedKVStore.SingleKVStore) => {
      if (err){
        console.log("数据库读取失败")
        return
      }
      this.friend_store = feedback

    })
    this.store.store?.getKVStore('message', options, (err, feedback: distributedKVStore.SingleKVStore) => {
      if (err){
        console.log("数据库读取失败")
        return
      }
      this.message_store = feedback
    })
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
          ForEach(Array.from(this.friends.flips), (item: [string, Friends[]]) => {
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