
interface Friends
{
  ID: string;
  Name: string;
  IconPath: string;
  PreView: string;
}


@Component
export struct Yours
{
  @State friends: Friends[] = []
  @Consume('PageStack') PageStack:NavPathStack;
  build()
  {
    List()
    {
      ForEach(this.friends, (item: Friends, index: number) =>
      {
        ListItem()
        {
          Row()
          {
            Image(item.IconPath)
            Column()
            {
              Text(item.Name)
              Text(item.PreView)
            }
          }
        }
      })
    }
  }
}