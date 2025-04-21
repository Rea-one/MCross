

@Component
export struct ChatPage
{
  @State messages: string[] = []
  build()
  {
    List()
    {
      ForEach(this.messages, (item: string, index: number) =>
      {
        ListItem()
        {
          
        }
      })
    }
  }
}