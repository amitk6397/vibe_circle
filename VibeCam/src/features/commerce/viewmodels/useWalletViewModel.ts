import { useCallback, useEffect, useState } from 'react';
import { walletApi } from '../../../services/api';
import { CoinPackage, UserWallet, WalletTransaction } from '../models/Commerce';

export function useWalletViewModel() {
  const [wallet, setWallet] = useState<UserWallet | null>(null);
  const [packages, setPackages] = useState<CoinPackage[]>([]);
  const [transactions, setTransactions] = useState<WalletTransaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hasMoreTransactions, setHasMoreTransactions] = useState(true);
  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [walletResult, packageResult, transactionResult] = await Promise.all([
        walletApi.get(),
        walletApi.packages(),
        walletApi.transactions(),
      ]);
      setWallet(walletResult.data);
      setPackages(packageResult.data);
      setTransactions(transactionResult.data);
      setHasMoreTransactions(transactionResult.data.length === 30);
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : 'Wallet could not load.');
    } finally {
      setLoading(false);
    }
  }, []);
  useEffect(() => {
    void refresh();
  }, [refresh]);
  const buy = useCallback(
    async (packageId: string) => {
      const result = await walletApi.buyCoins(packageId, `dummy_${Date.now()}_${packageId}`);
      setWallet(result.data);
      await refresh();
    },
    [refresh],
  );
  const loadMoreTransactions = useCallback(async () => {
    if (!transactions.length || !hasMoreTransactions) return;
    const { data } = await walletApi.transactions(transactions[transactions.length - 1].id);
    setTransactions((items) => [...items, ...data]);
    setHasMoreTransactions(data.length === 30);
  }, [transactions, hasMoreTransactions]);
  return {
    wallet,
    packages,
    transactions,
    loading,
    error,
    refresh,
    buy,
    loadMoreTransactions,
    hasMoreTransactions,
  };
}
