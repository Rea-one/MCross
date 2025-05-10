import { Storage } from "./storage";
import { distributedKVStore, preferences } from "@kit.ArkData";
import { Linker } from "./linker";
import { socket } from "@kit.NetworkKit";
import { fileIo } from "@kit.CoreFileKit"
import { Pref } from "./preference";
import { image } from '@kit.ImageKit';
import { MaxCountType, MaxSelected } from "@kit.MediaLibraryKit";
import { AbilityConstant, common, UIAbility, Want } from '@kit.AbilityKit';



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

class NetworkService {
  private link: Linker;

  constructor(link: Linker) {
    this.link = link;
  }

  onMessageReceived(callback: (data: Feedback) => void) {
    this.link.link.on("message", (info: socket.SocketMessageInfo) => {
      const decoded = this.arrayBufferToString(info.message);
      try {
        const feedback: Feedback = JSON.parse(decoded);
        callback(feedback);
      } catch (error) {
        console.error("解析消息失败", error);
      }
    });
  }

  arrayBufferToString(buffer: ArrayBuffer): string {
    let str = '';
    const dataView = new DataView(buffer);
    for (let order = 0; order < dataView.byteLength; order++) {
      str += String.fromCharCode(dataView.getUint8(order));
    }
    return str;
  }
}

class StoreService {
  private self: Pref = new Pref()
  private store: Storage;
  private options: distributedKVStore.Options;

  constructor(store: Storage, options: distributedKVStore.Options) {
    this.store = store;
    this.options = options;
  }

  getConfig() {
    return this.self.dp
  }

  async getFriendsStore(): Promise<distributedKVStore.SingleKVStore> {
    return await this.store.get_store("ones", this.options);
  }

  async getMessagesStore(): Promise<distributedKVStore.SingleKVStore> {
    return await this.store.get_store("messages", this.options);
  }

  async getImageStore(): Promise<distributedKVStore.SingleKVStore> {
    return await this.store.get_store("image", this.options);
  }
  async getSignalStore(): Promise<distributedKVStore.SingleKVStore> {
    return await this.store.get_store("signal", this.options);
  }
  // 提供读写接口
}

class waiter {
  self: One = {
    ID: "",
    Name: "",
    IconID: ""
  }
  timestamp = ""
  feedback: Feedback = {
    Image: "",
    Message: "",
    Receiver: "",
    Sender: "",
    State: "",
    Timestamp: ""
  }
  the_frd: Map<string, string[]> = new Map<string, string[]>()
  the_sgn: Map<string, One> = new Map<string, One>()
  the_msg: Map<string, [string, string][]> = new Map<string, [string, string][]>()
  the_img: Map<string, string> = new Map<string, string>()
  cfg_s: preferences.Preferences | null = null
  frd_s: distributedKVStore.SingleKVStore | null = null
  sgn_s: distributedKVStore.SingleKVStore | null = null
  msg_s: distributedKVStore.SingleKVStore | null = null
  img_s: distributedKVStore.SingleKVStore | null = null
  options: distributedKVStore.Options = {
    createIfMissing: true,
    encrypt: false,
    backup: false,
    autoSync: false,
    kvStoreType: distributedKVStore.KVStoreType.DEVICE_COLLABORATION,
    securityLevel: distributedKVStore.SecurityLevel.S3
  }

  async init(self: One, net_man: NetworkService): Promise<void> {
  this.self = self;
  const store = new StoreService(new Storage(), this.options);
  this.cfg_s = store.getConfig();

  try {
    const stores = await Promise.all([
      store.getFriendsStore(),
      store.getMessagesStore(),
      store.getImageStore(),
      store.getSignalStore()
    ]);

    const frdStore = stores[0];
    const msgStore = stores[1];
    const imgStore = stores[2];
    const sgnStore = stores[3];

    this.frd_s = frdStore;
    this.msg_s = msgStore;
    this.img_s = imgStore;
    this.sgn_s = sgnStore;

    // 并行加载数据
    await Promise.all([
      this.getFrdFS(),
      this.getMsgFS(),
      this.getImgFS(),
      this.getSgnFS(),
      this.getSelfFS()
    ]);

    // 监听消息
    net_man.onMessageReceived((receivedFeedback: Feedback) => {
      // 更新 feedback 和 timestamp
      this.feedback = receivedFeedback;
      console.info("接收到新消息", this.feedback);

      switch (this.feedback.State) {
        case "message":
          const sender = this.feedback.Sender;
          const receiver = this.feedback.Receiver;
          const message = [sender, this.feedback.Message];
          if (sender !== this.self.ID) {
            this.the_msg[sender]?.push(message as [string, string]);
          } else {
            this.the_msg[receiver]?.push(message as [string, string]);
          }
          break;
        case "image":
          this.the_img[this.feedback.Image] = `http://${this.feedback.Message}/${this.feedback.Image}`;
          break;
      }

      if (this.feedback.Timestamp) {
        this.timestamp = this.feedback.Timestamp;
      }

      void this.try_sync();
    });

  } catch (error) {
    console.error("初始化失败", error);
  }
}

  getFrd(index: string): string[] | void {
    return this.the_frd[index]
  }
  getSgn(index: string): One | void {
    return this.the_sgn[index]
  }

  getMsg(index: string): [string, boolean][] | void {
    return this.the_msg[index]
  }

  getImg(index: string): string {
    return this.the_img[index]
  }

  async try_sync() {
  this.cfg_s?.get("timestamp", async (value: string | null) => {
    if (typeof value === 'string') {
      if (this.timestamp === "" || this.timestamp < value) {
        this.cfg_s?.put("timestamp", this.timestamp);
        this.cfg_s?.flush();
        console.info("本地缓存已更新为最新时间戳:", this.timestamp);

        // 同步所有数据到分布式存储
        await this.saveImage();
        await this.saveSignal();
        await this.saveMessage();
        await this.saveFriend();
      } else {
        this.timestamp = value;
        console.info("使用本地缓存时间戳:", this.timestamp);
      }
    } else {
      this.cfg_s?.put("timestamp", this.timestamp);
      this.cfg_s?.flush();
      console.info("首次写入时间戳到缓存:", this.timestamp);
    }
  });
}
  async getSelfFS() {
    this.cfg_s?.get("timestamp", async (val: string | null) => {
      if (val != null) {
        if (this.self === null || this.timestamp == "" || this.timestamp < val) {
          this.cfg_s?.get("self", async (value: string | null) => {
            if (value != null) {
              this.self = JSON.parse(value)
            }
          })
        }
      }
    })
  }

  async getFrdFS() {
    if (!this.frd_s) {
      console.error("好友存储未初始化");
      return;
    }
    // 从分布式存储中获取所有好友数据
    this.frd_s.getEntries("", (err, val) => {
      for (let key of val.keys()) {
        this.the_frd[key.toString()] = val[key]
      }
    })
  }

  async getSgnFS() {
    if (!this.sgn_s) {
      console.error("信息存储未初始化");
      return;
    }
    this.sgn_s.getEntries("", (err, val) => {
      for (let key of val.keys()) {
        this.the_sgn[key.toString()] = JSON.parse(val[key].toString())
      }
    })
  }

  async getMsgFS() {
    if (!this.msg_s) {
      console.error("消息存储未初始化");
      return;
    }
    this.msg_s.getEntries("", (err, val) => {
      for (let key of val.keys()) {
        let rec = val[key].toString().split(" ")
        this.the_msg[key] = [rec[0], rec]
      }
    })
  }

  async getImgFS() {
  if (!this.frd_s) {
    console.error("图像存储未初始化");
    return;
  }
  this.frd_s.getEntries("", (err, val) => {
    for (let key of val.keys()) {
      this.the_img[key.toString()] = val[key]
    }
  });
}


  async saveFriend() {
    if (!this.frd_s) return;
    for (let elem of this.the_frd) {
      let rec = ""
      for (let tar of elem[1]){
        rec += tar + " "
      }
      this.frd_s.put(elem[0], rec)
    }
  }

  async saveSignal() {
    if (!this.sgn_s) return;
    for (let elem of this.the_sgn) {
      this.sgn_s.put(elem[0], JSON.stringify(elem[1]))
    }
  }

  async saveMessage() {
    if (!this.msg_s) return;
    for (let elem of this.the_msg) {
      this.msg_s.put(elem[0], elem[1][0] + " " + elem[1][1])
    }
  }
  async saveImage() {
  if (!this.img_s) return;
  for (let elem of this.the_img) {
    await this.img_s.put(elem[0], elem[1]); // 将每个图像映射写入分布式存储
  }
}
  async  saveConfig() {
    if (!this.cfg_s) return;
    await this.cfg_s.put("timestamp", this.timestamp)
    await this.cfg_s.put("self", JSON.stringify(this.self))
  }
}