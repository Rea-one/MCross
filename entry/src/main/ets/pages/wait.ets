

@Component
export struct WaitPage
{
  @Consume('pageStack') pageStack:NavPathStack
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