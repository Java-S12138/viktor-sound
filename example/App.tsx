import {View, Text, TouchableOpacity, ScrollView} from "react-native";
import * as Viktor from "viktor-sound"

export default function App () {

  const handlePlay = (word:string) => {
    Viktor.play(word,'us',{
      'x-crypto': 'Viktor=c60782ec0bf2cb72f918a9c352b07c337e821eedd5f39854bfd2cdb23e21f7ad; BFH=579653765086; ZCY=472327258738; SYJ=174806218815; XJH=XJH\n'
    })
  }

  const cet6Words = [
    "abandon",
    "bias",
    "capacity",
    "deduce",
    "elaborate",
    "fluctuate",
    "gratify",
    "hypothesis",
    "implication",
    "justify",
    "legitimate",
    "manifest",
    "notion",
    "offset",
    "prestige",
    "quantify",
    "retain",
    "suspend",
    "tangible",
    "undermine"
  ];

  return (
    <ScrollView style={{marginTop:100,marginLeft:100}}
    contentContainerStyle={{gap:12}}
    >
      {
        cet6Words.map((item)=>{
          return (
            <TouchableOpacity
              key={item}
              onPress={() => {
                handlePlay(item)
              }}
            >
              <Text style={{fontSize:18}}>
                {item}
              </Text>
            </TouchableOpacity>
          )
        })
      }

      </ScrollView>
  )
}

