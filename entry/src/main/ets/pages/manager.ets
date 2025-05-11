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

export class NetworkService {
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
  send(message: string){
    this.link.void_send(message)
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

export class Waiter {
  public self: One = {
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
  public the_frd: Map<string, string[]> = new Map<string, string[]>()
  public the_sgn: Map<string, One> = new Map<string, One>()
  public the_msg: Map<string, [string, string][]> = new Map<string, [string, string][]>()
  public the_img: Map<string, string> = new Map<string, string>()
  public the_hot: string[] = []

  cfg_s: preferences.Preferences | null = null
  frd_s: distributedKVStore.SingleKVStore | null = null
  sgn_s: distributedKVStore.SingleKVStore | null = null
  msg_s: distributedKVStore.SingleKVStore | null = null
  img_s: distributedKVStore.SingleKVStore | null = null
  options: distributedKVStore.Options | null = null

  async init(opt: distributedKVStore.Options, net_man: NetworkService): Promise<void> {
    this.options = opt
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
        this.getSelfFS(),
        this.getHotFS()
      ]);

      // 监听消息
      net_man.onMessageReceived((receivedFeedback: Feedback) => {
        // 更新 feedback 和 timestamp
        this.feedback = receivedFeedback;
        console.info("接收到新消息", this.feedback);
        switch (this.feedback.State) {
          case "login success":
            if (this.feedback.Sender != this.self.ID) {
              this.change()
              this.self.ID = this.feedback.Sender
            }
          case "message":
            const sender = this.feedback.Sender;
            const receiver = this.feedback.Receiver;
            const message = [sender, this.feedback.Message];
            let target = ""
            if (sender !== this.self.ID) {
              this.the_msg[sender].push(sender, message);
              target = sender
            } else {
              this.the_msg[receiver].push(sender, message);
              target = receiver
            }
            let sign = true
            for (let elem of this.the_hot) {
              if (elem == target) {
                sign = false
              }
            }
            if (sign){
              this.the_hot.push(target)
              this.the_hot.pop()
            }
            break;
          case "image":
            this.the_img[this.feedback.Image] = `http://${this.feedback.Message}/${this.feedback.Image}`;
            break;
          case "group":
            this.the_frd[this.feedback.Message] = this.feedback.Sender
            break
          case "config":
            if (this.self.ID == "" || this.feedback.Sender == this.self.ID) {
              this.self.ID = this.feedback.Sender
              this.self.Name = this.feedback.Message
              this.self.IconID = this.feedback.Image
            } else {
              this.the_sgn[this.feedback.Sender].ID = this.feedback.Sender
              this.the_sgn[this.feedback.Sender].Name = this.feedback.Message
              this.the_sgn[this.feedback.Sender].IconID = this.feedback.Image
            }
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

  async change(): Promise<void> {
    // 清除当前用户信息
    this.self = {
      ID: "",
      Name: "",
      IconID: ""
    };
    this.timestamp = "";

    // 清空聊天记录、联系人、热门联系人等数据
    this.the_frd.clear();
    this.the_sgn.clear();
    this.the_msg.clear();
    this.the_hot = [];

    // 清空本地缓存
    if (this.cfg_s) {
      await this.cfg_s.clear(); // 清除 preferences 缓存
      await this.cfg_s.flush();
    }

    // 如果有同步需求，也可以清空分布式存储中的内容
    if (this.frd_s) await clearKVStore(this.frd_s);
    if (this.sgn_s) await clearKVStore(this.sgn_s);
    if (this.msg_s) await clearKVStore(this.msg_s);

    console.info("账号信息已重置");
  }

  getFrd(index: string): string[] | void {
    return this.the_frd[index]
  }
  getSgn(index: string): One {
    return this.the_sgn[index]
  }

  getMsg(index: string): [string, boolean][] | void {
    return this.the_msg[index]
  }

  getImg(index: string): string {
    return this.the_img[index]
  }

  getHot(){
    return this.the_hot
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

  async getHotFS(): Promise<void> {
    if (!this.cfg_s) {
      console.error("配置存储未初始化");
      return;
    }

    this.cfg_s.get("hot", (val: string) => {
      if (typeof val === 'string' && val.trim()) {
        this.the_hot = val.split(",");
      } else {
        this.the_hot = [];
      }
    })
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
      await this.img_s.put(elem[0], elem[1]);
    }
  }
  async saveConfig() {
    if (!this.cfg_s) return;
    await this.cfg_s.put("timestamp", this.timestamp)
    await this.cfg_s.put("self", JSON.stringify(this.self))
    await this.cfg_s.put("hot", this.the_hot.join(","))
  }
}

async function clearKVStore(store: distributedKVStore.SingleKVStore): Promise<void> {
  const entries = await store.getEntries("");
  for (const entry of entries) {
    await store.delete(entry.key);
  }
}