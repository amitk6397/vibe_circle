import React from 'react';
import { CallScreenContent } from '../components/CallScreenContent';

export default function AudioCallScreen({ navigation, route }: any) {
  return (
    <CallScreenContent
      callId={route.params.callId}
      name={route.params.name}
      personId={route.params.personId}
      video={false}
      onClose={(session) =>
        session?.chargedCoins || session?.usedCreditMinutes
          ? navigation.replace('SessionRating', {
              sessionId: session.id,
              userId: route.params.personId,
              sessionType: 'call',
            })
          : navigation.goBack()
      }
    />
  );
}
