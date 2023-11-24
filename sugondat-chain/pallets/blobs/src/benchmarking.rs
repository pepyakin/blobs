//! Benchmarking setup for pallet-sugondat-blobs
use super::*;

#[allow(unused)]
use crate::Pallet as Blobs;
#[allow(unused)]
use frame_benchmarking::v2::{benchmarks, impl_benchmark_test_suite, whitelisted_caller};
use frame_support::{traits::Get, BoundedVec};
use frame_system::RawOrigin;
use sp_std::vec;

/* Command to run the benchmark:
 ./target/release/sugondat-node benchmark pallet \
 --dev \
 --pallet pallet_sugondat_blobs \
 --extrinsic '*' \
 --steps 10 \
 --repeat 20 \
 --template sugondat-chain/pallets/blobs/src/frame-weight-template.hbs \
 --output sugondat-chain/pallets/blobs/src/weights.rs
*/

#[benchmarks]
mod benchmarks {
    use super::*;

    #[benchmark]
    // x represent the amount of BlobsMetadata already stored in BlobList
    // while y is the size of the blob in bytes
    fn submit_blob(
        x: Linear<0, { T::MaxBlobs::get() - 1 }>,
        y: Linear<1, { T::MaxBlobSize::get() }>,
    ) {
        let caller: T::AccountId = whitelisted_caller();

        // save in the storage x random BlobMetadata
        // because every extrinsics call all the vec will be fetch
        // and re-written with the new BlobMetadata
        //
        // it shouldn't matter to use different values
        // it is ok to use always the same SubmittedBlobMetadata,
        let metadata = SubmittedBlobMetadata {
            who: caller.clone(),
            extrinsic_index: 1,
            namespace_id: 4,
            blob_hash: [5; 32],
        };

        // I could use repeat here if I derive clone for SubmittedBlobMetadata
        // under the feature runtime-bechmarks
        let mut blobs_list = BoundedVec::<_, T::MaxBlobs>::with_bounded_capacity(x as usize);
        for _ in 0..x {
            blobs_list.force_push(metadata.clone());
        }
        BlobList::<T>::put(blobs_list);

        // To mimic perfectly the behaviur the values zero
        // should be fetched by default being TotalBlobsSize not setted up
        if x > 0 {
            // the effective inserted size is not relevant for the scope of the bechmark
            TotalBlobsSize::<T>::put(x);
        }

        // Create a random blob that needs to be hashed on chain
        let blob: BoundedVec<u8, T::MaxBlobSize> = vec![23u8]
            .repeat(y as usize)
            .try_into()
            .expect("Impossible convert blob into BoundedVec");
        let namespace_id = 9;

        #[extrinsic_call]
        _(RawOrigin::Signed(caller), namespace_id, blob);

        // Check that an item is inserted in the BlobList and
        // the new value stored in TotalBlobSize is correct
        assert_eq!(BlobList::<T>::get().len(), x as usize + 1);
        assert_eq!(TotalBlobsSize::<T>::get(), x + y);
    }

    impl_benchmark_test_suite!(Blobs, crate::mock::new_test_ext(), crate::mock::Test);
}
