import ViktorSoundModule  from "./ViktorSoundModule"


export function play(word:string,type:string,header:Record<string, string>) {
  return ViktorSoundModule.playWithHeaders(word,type,header)
}
