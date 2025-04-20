

@Component
export struct WaitPage
{
  @Consume('PageStack') PageStack:NavPathStack
  build()
  {
    NavDestination()
    {
      Text('这是默认页')
        .width('100%')
        .fontColor(Color.Black)
    }
  }
}