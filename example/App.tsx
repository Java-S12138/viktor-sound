import {View, Text, TouchableOpacity} from "react-native";
import * as Viktor from "viktor-sound"

export default function App () {
  return (
    <View style={{flex:1,alignItems:"center",justifyContent:"center"}}>
      <Text>
        Theme:{Viktor.getTheme()}
      </Text>

      <TouchableOpacity
      onPress={() => {
        Viktor.play('good','uk',{
          'x-crypto': 'Viktor=e33e8f109759754cbb249ae0fcf789c95fc0eb1fe05813c61c282ab044cd4940; BFH=435071456406; ZCY=255833347505; SYJ=174860425251; XJH=XJH'
        }).catch((e)=>{
          console.log(e)
        })
      }}
      >
        <Text>
          play
        </Text>
      </TouchableOpacity>
    </View>
  )
}
