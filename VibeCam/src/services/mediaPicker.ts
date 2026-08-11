import { Alert } from 'react-native';
import * as DocumentPicker from 'expo-document-picker';
import * as ImagePicker from 'expo-image-picker';
import { LocalAttachment } from '../types';

const MAX_FILE_BYTES = 15 * 1024 * 1024;

export async function pickImage(allowsEditing = false): Promise<LocalAttachment | null> {
  const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
  if (!permission.granted) {
    Alert.alert('Photos permission required', 'Allow photo access to select and share an image.');
    return null;
  }

  const result = await ImagePicker.launchImageLibraryAsync({
    mediaTypes: ['images'],
    allowsEditing,
    quality: 0.85,
  });

  if (result.canceled) return null;
  const asset = result.assets[0];
  return {
    id: String(Date.now()),
    kind: 'image',
    uri: asset.uri,
    name: asset.fileName || `image-${Date.now()}.jpg`,
    mimeType: asset.mimeType,
    size: asset.fileSize,
  };
}

export async function pickStoryImages(): Promise<LocalAttachment[]> {
  const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
  if (!permission.granted) {
    Alert.alert('Photos permission required', 'Allow photo access to add stories.');
    return [];
  }
  const result = await ImagePicker.launchImageLibraryAsync({
    mediaTypes: ['images'],
    allowsMultipleSelection: true,
    selectionLimit: 10,
    quality: 0.85,
  });
  if (result.canceled) return [];
  return result.assets.map((asset, index) => ({
    id: `${Date.now()}-${index}`,
    kind: 'image' as const,
    uri: asset.uri,
    name: asset.fileName || `story-${Date.now()}-${index}.jpg`,
    mimeType: asset.mimeType,
    size: asset.fileSize,
  }));
}

export async function pickDocument(): Promise<LocalAttachment | null> {
  const result = await DocumentPicker.getDocumentAsync({
    type: '*/*',
    copyToCacheDirectory: true,
    multiple: false,
  });

  if (result.canceled) return null;
  const asset = result.assets[0];
  if (asset.size && asset.size > MAX_FILE_BYTES) {
    Alert.alert('File too large', 'Choose a file smaller than 15 MB.');
    return null;
  }

  return {
    id: String(Date.now()),
    kind: asset.mimeType?.startsWith('image/') ? 'image' : 'file',
    uri: asset.uri,
    name: asset.name,
    mimeType: asset.mimeType,
    size: asset.size,
  };
}

export function formatFileSize(size?: number) {
  if (!size) return 'Local file';
  if (size < 1024 * 1024) return `${Math.max(1, Math.round(size / 1024))} KB`;
  return `${(size / (1024 * 1024)).toFixed(1)} MB`;
}
