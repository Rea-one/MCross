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

interface Feedback {
  Image: string;
  Message: string;
  Receiver: string;
  Sender: string;
  State: string;
  Timestamp: string;
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
    const dataString = this.decode(stream.message); // 将 ArrayBuffer 转换为字符串

    try {
      const feedback: Feedback = JSON.parse(dataString); // 解析 JSON

      switch (feedback.State) {
        case "nomore":
          console.info(`关闭连接中，来自 ${feedback.Sender}`);
          // 执行关闭逻辑
          break;

        case "request image":
          console.info(`请求图片，ID: ${feedback.Image}`);
          // 请求图片逻辑，例如从 Pref 或 Storage 获取图片数据
          break;

        default:
          console.info(`收到消息: ${feedback.Message}, 时间戳: ${feedback.Timestamp}`);
        // 处理普通消息
          this.handleMessage(feedback.Sender, feedback.Message, feedback.Timestamp);
          break;
      }
    }
    catch (error) {
      console.error("解析反馈数据失败", error);
    }
  }
  decode(buffer: ArrayBuffer): Feedback | null {
    try {
      const dataString = this.arrayBufferToString(buffer).trim();

      if (!dataString) {
        console.error("解码失败：空数据");
        return null;
      }

      const feedback: Feedback = JSON.parse(dataString);
      return feedback;
    }
    catch (error) {
      console.error("解析反馈数据失败", error);
      return null;
    }
  }
  arrayBufferToString(buffer: ArrayBuffer): string {
    const dataView = new DataView(buffer);
    let str = '';
    for (let order = 0; order < dataView.byteLength; order++) {
      str += String.fromCharCode(dataView.getUint8(order));
    }
    return str;
  }
}