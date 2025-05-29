import { NativeModule, requireNativeModule } from 'expo';


declare class ViktorSoundModule extends NativeModule {
  playWithHeaders(word:string,type:string,header:Record<string, string>):Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ViktorSoundModule>('ViktorSound');
