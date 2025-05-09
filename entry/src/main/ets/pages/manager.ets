import { Storage } from "./storage";
import { distributedKVStore, preferences } from "@kit.ArkData";
import { Linker } from "./linker";
import { socket } from "@kit.NetworkKit";
import { fileIo } from "@kit.CoreFileKit"
import { Pref } from "./preference";
import { image } from '@kit.ImageKit';
import { MaxCountType, MaxSelected } from "@kit.MediaLibraryKit";
import { common, UIAbility } from '@kit.AbilityKit';



export interface One {
  ID: string;
  Name: string;
  IconID: string;
}

export interface  Message {
  timestamp: string,
  message: string,
  isSender: boolean
}

class SocketInfo {
  message: ArrayBuffer = new ArrayBuffer(1);
  remoteInfo: socket.SocketRemoteInfo = {} as socket.SocketRemoteInfo;
}

export class Manager extends UIAbility{
  private Options: distributedKVStore.Options = {
    createIfMissing: true,
    encrypt: false,
    backup: false,
    autoSync: false,
    kvStoreType: distributedKVStore.KVStoreType.DEVICE_COLLABORATION,
    securityLevel: distributedKVStore.SecurityLevel.S3
  }
  private POptions:  preferences.Options = { name: 'self' };
  private timestamp: string = ""
  private link:     Linker = new Linker()
  private store:    Storage = new Storage()
  private pref:     preferences.Preferences | null = null
  private hot:      distributedKVStore.SingleKVStore | null = null
  private Friends:     distributedKVStore.SingleKVStore | null = null
  private Messes: distributedKVStore.SingleKVStore | null = null
  private Groups:   distributedKVStore.SingleKVStore | null = null

  friends:  Map<string, One> = new Map<string, One>()
  messes:   Map<string, Message[]> = new Map<string, Message[]>()
  groups:   Map<string, string[]> = new Map<string, string[]>()

  Init(){
    this.store.get_store("hot", this.Options)
      .then((store) => {
        this.hot = store

      })
    this.store.get_store("ones", this.Options)
      .then((store) => {
        this.Friends = store
      })
    this.store.get_store("messages", this.Options)
      .then((store) => {
        this.Messes = store
      })
    this.store.get_store("group", this.Options)
      .then((store) => {
        this.Groups = store
      })
    this.pref = preferences.getPreferencesSync(this.context, this.POptions)
    this.timestamp = this.pref.getSync("timestamp", "default").toString()
  }

  update_this(){
    this.Friends?.getEntries("", (err, val) => {
      val.forEach(elem => {
        let rec = elem.value
        let targets = rec.value.toString().split(" ")
        this.friends[elem.key] = {
          ID: elem.key,
          Name: targets[0],
          IconID: targets[1]
        }
      })
    })
    this.Messes?.getEntries("", (err, val) => {
      val.forEach(elem => {
        let rec = elem.value
        let targets = rec.value.toString().split(" ")
        for (let order = 0; order < targets.length; order += 3) {
          this.messes[elem.key] = {
            timestamp:  targets[order],
            message:    targets[order + 1],
            isSender:   targets[order + 2]
          }
        }
      })
    })
    this.Groups?.getEntries("", (err, val) => {
      val.forEach(elem => {
        let rec = elem.value
        let targets = rec.value.toString().split(" ")
        this.groups[elem.key] = targets
      })
    })
    this.groups
  }

  react(stream: SocketInfo) {
    let buffer = stream.message
    let dataView = new DataView(buffer)

    let one_tar = ""

    let rec = ""
    let next = ""
    let now = ""
    for (let order = 0; order < dataView.byteLength; order ++) {
      now = String.fromCharCode(dataView.getUint8(order)).toString();
      if (now == " "){
        switch (rec) {
          case "time":
            for (order ++, now = String.fromCharCode(dataView.getUint8(order)).toString();
              now != " "; order ++){
              next += now
            }
            this.timestamp = next
            break
          case "friend":
            for (order ++, now = String.fromCharCode(dataView.getUint8(order)).toString();
              now != " "; order ++){
              next += now
            }
            one_tar = next
            break
          case "message":
            for (order ++, now = String.fromCharCode(dataView.getUint8(order)).toString();
              now != " "; order ++){
              next += now
            }
            this.messes[one_tar]
        }
      } else {
        rec += now
      }
    }
  }
}