

export class Method {
  login(name: string, password: string){
    return 's ${name} pw ${password} t lg'
  }

  register(name: string, password: string){
    return 's ${name} pw ${password} t rg'
  }
}