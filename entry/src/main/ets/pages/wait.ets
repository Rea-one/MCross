

@Component
export struct WaitPage
{
  @Consume('pageStack') pageStack:NavPathStack
  build()
  {
    NavDestination()
    {
      Column(){
        Text('这是默认页')
          .fontColor(Color.Black)
          .fontSize(30)
          .textAlign(TextAlign.Center)
          .height("30%")
          .width("100%")
      }
      .alignItems(HorizontalAlign.Center)
    }
  }
}